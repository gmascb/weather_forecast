module Flow
  module Forecast
    module Subscribers
      class ValidateZipCodeFlowSubscriber < Flows::SimpleCatchFlowSubscriber
        # Matches exactly 5 digits from start (\A) to end (\z) of the string, e.g. "10001".
        ZIP_CODE_FORMAT = /\A\d{5}\z/

        def execute(flow_context)
          zip_code = flow_context[:zip_code]
          Rails.logger.info("[Forecast::ValidateZipCode] Validating zip_code=#{zip_code}")

          if zip_code.blank?
            flow_context[:error] = "Zip code is required"
            flow_context[:status] = :bad_request
            return
          end

          unless zip_code.match?(ZIP_CODE_FORMAT)
            flow_context[:error] = "Zip code must be a 5-digit US zip code (e.g. 10001)"
            flow_context[:status] = :bad_request
          end
        end

        def catch(exception, flow_context)
          Rails.logger.error("[Forecast::ValidateZipCode] Unexpected error: #{exception.message}")
          flow_context[:error] = "Validation failed unexpectedly"
          flow_context[:status] = :internal_server_error
        end
      end
    end
  end
end
