module Flow
  module Forecast
    module Subscribers
      class FetchWeatherFlowSubscriber < Flows::SimpleCatchFlowSubscriber
        FORECAST_URL = "https://api.open-meteo.com/v1".freeze

        def execute(flow_context)
          return if flow_context[:error] || flow_context[:from_cache]

          Rails.logger.info("[Forecast::FetchWeather] Fetching forecast for (#{flow_context[:latitude]}, #{flow_context[:longitude]})")

          response = connection.get("forecast", {
            latitude: flow_context[:latitude],
            longitude: flow_context[:longitude],
            current: "temperature_2m,relative_humidity_2m,apparent_temperature,weather_code",
            daily: "temperature_2m_max,temperature_2m_min,weather_code",
            temperature_unit: "fahrenheit",
            timezone: "auto",
            forecast_days: 5
          })

          flow_context[:raw_weather] = JSON.parse(response.body, symbolize_names: true)
          Rails.logger.info("[Forecast::FetchWeather] Successfully fetched weather data")
        end

        def catch(exception, flow_context)
          Rails.logger.error("[Forecast::FetchWeather] Failed: #{exception.class} - #{exception.message}")
          flow_context[:error] = "Weather service is temporarily unavailable"
          flow_context[:status] = :service_unavailable
        end

        private

        def connection
          @connection ||= Faraday.new(url: FORECAST_URL) { |f| f.response :raise_error }
        end
      end
    end
  end
end
