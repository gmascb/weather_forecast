module Api
  module V1
    class ForecastsController < ApplicationController
      def show
        result = Weather::Service.new(params[:zip_code], country_code: params[:country_code]).call

        if result[:error]
          render json: { error: result[:error] }, status: result[:status]
        else
          render json: result, status: :ok
        end
      end
    end
  end
end
