module Flow
  module Forecast
    module Subscribers
      class CheckCacheFlowSubscriber < Flows::SimpleCatchFlowSubscriber
        def execute(flow_context)
          return if flow_context[:error]

          zip_code = flow_context[:zip_code]
          Rails.logger.info("[Forecast::CheckCache] Checking cache for zip_code=#{zip_code}")

          cached_data = Rails.cache.read(cache_key(zip_code))
          return unless cached_data

          Rails.logger.info("[Forecast::CheckCache] Cache HIT for zip_code=#{zip_code}")
          flow_context[:response] = cached_data.merge(cached: true)
          flow_context[:from_cache] = true
        end

        def catch(exception, flow_context)
          Rails.logger.error("[Forecast::CheckCache] Cache read failed: #{exception.message}")
          flow_context[:from_cache] = false
        end

        private

        def cache_key(zip_code)
          "forecast_v2_#{zip_code}"
        end
      end
    end
  end
end
