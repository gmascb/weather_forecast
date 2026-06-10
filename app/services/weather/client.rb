# HTTP client for the Open-Meteo API (https://open-meteo.com).
#
# Open-Meteo exposes two separate endpoints:
#   1. Geocoding API — resolves a location name or zip code into coordinates (lat/lng).
#   2. Forecast API  — returns weather data for a given pair of coordinates.
#
# A forecast request is always a two-step process:
#   zip_code → [Geocoding API] → lat/lng → [Forecast API] → weather data
module Weather
  class Client
    include Helpers::WmoDescriptions

    GEOCODING_URL = "https://geocoding-api.open-meteo.com/v1".freeze
    FORECAST_URL  = "https://api.open-meteo.com/v1".freeze

    def initialize
      # Each API lives on a different subdomain, so we need separate Faraday connections.
      # :raise_error middleware automatically raises Faraday::Error on 4xx/5xx responses.
      @geocoding_conn = Faraday.new(url: GEOCODING_URL) { |f| f.response :raise_error }
      @forecast_conn  = Faraday.new(url: FORECAST_URL)  { |f| f.response :raise_error }
    end

    def forecast(zip_code, country_code: "us")
      location = geocode(zip_code, country_code: country_code)
      return { error: "Could not find location for zip code #{zip_code}" } unless location

      data = fetch_weather(location[:latitude], location[:longitude])

      {
        current: parse_current(data, location),
        forecast: parse_daily(data)
      }
    rescue Faraday::Error => e
      Rails.logger.error("[Weather::Client] Forecast request failed: #{e.class} - #{e.message}")
      { error: "Weather service is temporarily unavailable" }
    end

    private

    # -- Step 1: Geocoding (zip code → coordinates) ----------------------------
    def geocode(zip_code, country_code: "us")
      Rails.logger.info("[Weather::Client] Geocoding zip_code=#{zip_code}")

      response = @geocoding_conn.get("search", {
        name: zip_code,
        count: 5,
        language: "en",
        format: "json"
      })
      results = JSON.parse(response.body, symbolize_names: true)[:results] || []

      location = results.find { |r| r[:country_code] == country_code.upcase } || results.first

      if location
        Rails.logger.info("[Weather::Client] Resolved to #{location[:name]} (#{location[:latitude]}, #{location[:longitude]})")
      else
        Rails.logger.warn("[Weather::Client] No location found for zip_code=#{zip_code}")
      end

      location
    rescue Faraday::Error => e
      Rails.logger.error("[Weather::Client] Geocoding failed: #{e.class} - #{e.message}")
      nil
    end

    # -- Step 2: Forecast (coordinates → weather data) -------------------------
    def fetch_weather(latitude, longitude)
      Rails.logger.info("[Weather::Client] Fetching weather for (#{latitude}, #{longitude})")

      response = @forecast_conn.get("forecast", {
        latitude: latitude,
        longitude: longitude,
        current: "temperature_2m,relative_humidity_2m,apparent_temperature,weather_code",
        daily: "temperature_2m_max,temperature_2m_min,weather_code",
        temperature_unit: "fahrenheit",
        timezone: "auto",
        forecast_days: 5
      })

      JSON.parse(response.body, symbolize_names: true)
    end

    # -- Response parsing -------------------------------------------------------
    def parse_current(data, location)
      current = data[:current]
      daily   = data[:daily]

      {
        name: location[:name],
        temp: current[:temperature_2m],
        feels_like: current[:apparent_temperature],
        temp_min: daily[:temperature_2m_min]&.first,
        temp_max: daily[:temperature_2m_max]&.first,
        humidity: current[:relative_humidity_2m],
        description: wmo_description(current[:weather_code])
      }
    end

    def parse_daily(data)
      daily = data[:daily]

      daily[:time].each_with_index.map do |date, i|
        {
          date: date,
          temp_min: daily[:temperature_2m_min][i],
          temp_max: daily[:temperature_2m_max][i],
          description: wmo_description(daily[:weather_code][i])
        }
      end
    end
  end
end
