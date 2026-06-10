module Flow
  module Forecast
    module Subscribers
      class GeocodeLocationFlowSubscriber < Flows::SimpleCatchFlowSubscriber
        GEOCODING_URL = "https://geocoding-api.open-meteo.com/v1".freeze

        def execute(flow_context)
          return if flow_context[:error] || flow_context[:from_cache]

          Rails.logger.info("[Forecast::Geocode] Geocoding zip_code=#{flow_context[:zip_code]}")

          response = connection.get("search", {
            name: flow_context[:zip_code],
            count: 5,
            language: "en",
            format: "json"
          })

          results = JSON.parse(response.body, symbolize_names: true)[:results] || []
          location = results.find { |r| r[:country_code] == flow_context[:country_code].upcase } || results.first

          unless location
            flow_context[:error] = "Could not find location for zip code #{flow_context[:zip_code]}"
            flow_context[:status] = :unprocessable_entity
            return
          end

          flow_context[:latitude] = location[:latitude]
          flow_context[:longitude] = location[:longitude]
          flow_context[:location_name] = location[:name]
          Rails.logger.info("[Forecast::Geocode] Resolved to #{location[:name]} (#{location[:latitude]}, #{location[:longitude]})")
        end

        def catch(exception, flow_context)
          Rails.logger.error("[Forecast::Geocode] Failed: #{exception.class} - #{exception.message}")
          flow_context[:error] = "Weather service is temporarily unavailable"
          flow_context[:status] = :service_unavailable
        end

        private

        def connection
          @connection ||= Faraday.new(url: GEOCODING_URL) { |f| f.response :raise_error }
        end
      end
    end
  end
end
