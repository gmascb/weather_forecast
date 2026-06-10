module Weather
  class Service
    CACHE_TTL = 30.minutes
    # Matches exactly 5 digits from start (\A) to end (\z) of the string, e.g. "10001".
    ZIP_CODE_FORMAT = /\A\d{5}\z/

    def initialize(zip_code, country_code: "us")
      @zip_code = zip_code.to_s.strip
      @country_code = country_code || "us"
    end

    def call
      Rails.logger.info("[Weather::Service] Starting forecast request for zip_code=#{@zip_code} country_code=#{@country_code}")

      error = validate
      if error
        Rails.logger.error("[Weather::Service] Validation failed: #{error[:error]}")
        return error
      end

      cached = read_cache
      if cached
        Rails.logger.info("[Weather::Service] Cache HIT for zip_code=#{@zip_code}")
        return cached.merge(cached: true)
      end

      forecast = request_forecast
      return forecast if forecast[:error]

      data = build_response(forecast)
      write_cache(data)

      Rails.logger.info("[Weather::Service] Forecast request completed successfully for zip_code=#{@zip_code}")
      data.merge(cached: false)
    rescue => e
      Rails.logger.error("[Weather::Service] Unexpected failure: #{e.class} - #{e.message}")
      raise
    end

    private

    def validate
      if @zip_code.blank?
        return { error: "Zip code is required", status: :bad_request }
      end

      unless @zip_code.match?(ZIP_CODE_FORMAT)
        return { error: "Zip code must be a 5-digit US zip code (e.g. 10001)", status: :bad_request }
      end

      nil
    end

    def cache_key
      "forecast_#{@zip_code}"
    end

    def read_cache
      Rails.cache.read(cache_key)
    end

    def write_cache(data)
      Rails.cache.write(cache_key, data, expires_in: CACHE_TTL)
    end

    def request_forecast
      result = Weather::Client.new.forecast(@zip_code, country_code: @country_code)

      if result[:error]
        return { error: result[:error], status: :unprocessable_entity }
      end

      result
    end

    def build_response(raw)
      {
        zip_code: @zip_code,
        location: raw[:current][:name],
        current_temperature: raw[:current][:temp],
        feels_like: raw[:current][:feels_like],
        temp_min: raw[:current][:temp_min],
        temp_max: raw[:current][:temp_max],
        humidity: raw[:current][:humidity],
        description: raw[:current][:description],
        extended_forecast: build_extended_forecast(raw[:forecast])
      }
    end

    def build_extended_forecast(days)
      days.map do |day|
        {
          date: day[:date],
          temp_min: day[:temp_min],
          temp_max: day[:temp_max],
          description: day[:description]
        }
      end
    end
  end
end
