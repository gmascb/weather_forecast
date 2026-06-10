module Api
  module V2
    class ForecastsController < ApplicationController
      def show
        result = Flow::Forecast::ForecastFlowController.new(
          flow_context: {
            zip_code: params[:zip_code].to_s.strip,
            country_code: params[:country_code] || "us"
          }
        ).execute

        if result[:error]
          render json: { error: result[:error] }, status: result[:status]
        else
          render json: result[:response], status: :ok
        end
      end
    end
  end
end
