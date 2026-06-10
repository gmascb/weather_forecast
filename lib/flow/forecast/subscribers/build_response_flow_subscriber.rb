module Flow
  module Forecast
    module Subscribers
      class BuildResponseFlowSubscriber < Flows::SimpleCatchFlowSubscriber
        include Helpers::WmoDescriptions

        def execute(flow_context)
          return if flow_context[:error] || flow_context[:from_cache]

          Rails.logger.info("[Forecast::BuildResponse] Building response for zip_code=#{flow_context[:zip_code]}")

          data = flow_context[:raw_weather]
          current = data[:current]
          daily = data[:daily]

          flow_context[:response] = {
            zip_code: flow_context[:zip_code],
            location: flow_context[:location_name],
            current_temperature: current[:temperature_2m],
            feels_like: current[:apparent_temperature],
            temp_min: daily[:temperature_2m_min]&.first,
            temp_max: daily[:temperature_2m_max]&.first,
            humidity: current[:relative_humidity_2m],
            description: wmo_description(current[:weather_code]),
            cached: false,
            extended_forecast: build_forecast(daily)
          }
        end

        def catch(exception, flow_context)
          Rails.logger.error("[Forecast::BuildResponse] Failed: #{exception.class} - #{exception.message}")
          flow_context[:error] = "Failed to process weather data"
          flow_context[:status] = :internal_server_error
        end

        private

        def build_forecast(daily)
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
  end
end
