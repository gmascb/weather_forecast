require "swagger_helper"

RSpec.describe "Forecasts API", type: :request, openapi_spec: "v1/swagger.yaml" do
  path "/api/v1/forecast" do
    get "Retrieve weather forecast for a given zip code" do
      tags "Forecasts"
      description <<~DESC
        Returns the current weather conditions and a 5-day extended forecast for the given US zip code.

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
                 zip_code: { type: :string, example: "10001", description: "The zip code used for the lookup" },
                 location: { type: :string, example: "New York", description: "Resolved location name" },
                 current_temperature: { type: :number, example: 72.5, description: "Current temperature in Fahrenheit" },
                 feels_like: { type: :number, example: 70.1, description: "Perceived temperature in Fahrenheit" },
                 temp_min: { type: :number, example: 68.0, description: "Today's minimum temperature in Fahrenheit" },
                 temp_max: { type: :number, example: 76.0, description: "Today's maximum temperature in Fahrenheit" },
                 humidity: { type: :integer, example: 55, description: "Relative humidity percentage" },
                 description: { type: :string, example: "clear sky", description: "Human-readable weather description" },
                 cached: { type: :boolean, example: false, description: "Whether the result was served from cache" },
                 extended_forecast: {
                   type: :array,
                   description: "5-day forecast starting from today",
                   items: {
                     type: :object,
                     properties: {
                       date: { type: :string, example: "2025-06-10", description: "Date in YYYY-MM-DD format" },
                       temp_min: { type: :number, example: 65.0, description: "Minimum temperature in Fahrenheit" },
                       temp_max: { type: :number, example: 76.0, description: "Maximum temperature in Fahrenheit" },
                       description: { type: :string, example: "partly cloudy", description: "Weather description for the day" }
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
