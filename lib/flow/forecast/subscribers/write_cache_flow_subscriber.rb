module Flow
  module Forecast
    module Subscribers
      class WriteCacheFlowSubscriber < Flows::SimpleCatchFlowSubscriber
        CACHE_TTL = 30.minutes

        def execute(flow_context)
          return if flow_context[:error] || flow_context[:from_cache]

          Rails.logger.info("[Forecast::WriteCache] Caching response for zip_code=#{flow_context[:zip_code]}")

          data = flow_context[:response].except(:cached)
          Rails.cache.write(cache_key(flow_context[:zip_code]), data, expires_in: CACHE_TTL)
        end

        def catch(exception, flow_context)
          Rails.logger.error("[Forecast::WriteCache] Cache write failed: #{exception.message}")
        end

        private

        def cache_key(zip_code)
          "forecast_v2_#{zip_code}"
        end
      end
    end
  end
end
