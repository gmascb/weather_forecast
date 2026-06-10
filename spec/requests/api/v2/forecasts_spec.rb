require "swagger_helper"

RSpec.describe "Forecasts API V2", type: :request, openapi_spec: "v2/swagger.yaml" do
  path "/api/v2/forecast" do
    get "Retrieve weather forecast using FlowSubscribers pattern" do
      tags "Forecasts V2"
      description <<~DESC
        Returns the current weather conditions and a 5-day extended forecast for the given US zip code.
        This endpoint uses the FlowSubscribers pattern for organized business logic.

        - Results are **cached for 30 minutes** per zip code.
        - The `cached` field in the response indicates whether the data came from the cache.
        - Temperatures are returned in **Fahrenheit**.
      DESC
      produces "application/json"

      parameter name: :zip_code, in: :query, type: :string, required: true,
                description: "5-digit US zip code",
                example: "10001"

      parameter name: :country_code, in: :query, type: :string, required: false,
                description: "ISO 3166-1 alpha-2 country code (defaults to 'us')",
                example: "us"

      response "200", "Forecast retrieved successfully" do
        schema type: :object,
               properties: {
                 zip_code: { type: :string, example: "10001" },
                 location: { type: :string, example: "New York" },
                 current_temperature: { type: :number, example: 72.5 },
                 feels_like: { type: :number, example: 70.1 },
                 temp_min: { type: :number, example: 68.0 },
                 temp_max: { type: :number, example: 76.0 },
                 humidity: { type: :integer, example: 55 },
                 description: { type: :string, example: "clear sky" },
                 cached: { type: :boolean, example: false },
                 extended_forecast: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       date: { type: :string, example: "2025-06-10" },
                       temp_min: { type: :number, example: 65.0 },
                       temp_max: { type: :number, example: 76.0 },
                       description: { type: :string, example: "partly cloudy" }
                     },
                     required: %w[date temp_min temp_max description]
                   }
                 }
               },
               required: %w[zip_code location current_temperature cached]

        let(:zip_code) { "10001" }

        before { stub_weather_api_success(zip_code: "10001") }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["zip_code"]).to eq("10001")
          expect(data["cached"]).to eq(false)
        end
      end

      response "400", "Missing or invalid zip code" do
        schema type: :object,
               properties: {
                 error: { type: :string, example: "Zip code is required" }
               },
               required: %w[error]

        let(:zip_code) { "" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Zip code is required")
        end
      end

      response "422", "Location not found for the given zip code" do
        schema type: :object,
               properties: {
                 error: { type: :string, example: "Could not find location for zip code 00000" }
               },
               required: %w[error]

        let(:zip_code) { "00000" }

        before { stub_weather_api_not_found(zip_code: "00000") }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to be_present
        end
      end
    end
  end
end
