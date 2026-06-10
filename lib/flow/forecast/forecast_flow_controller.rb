module Flow
  module Forecast
    class ForecastFlowController < Flows::SimpleFlowController
      def initialize(flow_context:, transactional: false)
        super(
          flows: [
            Subscribers::ValidateZipCodeFlowSubscriber.new,
            Subscribers::CheckCacheFlowSubscriber.new,
            Subscribers::GeocodeLocationFlowSubscriber.new,
            Subscribers::FetchWeatherFlowSubscriber.new,
            Subscribers::BuildResponseFlowSubscriber.new,
            Subscribers::WriteCacheFlowSubscriber.new
          ],
          flow_context: flow_context,
          transactional: transactional
        )
      end
    end
  end
end
