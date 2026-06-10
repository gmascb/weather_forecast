require "rails_helper"

RSpec.describe Flow::Forecast::ForecastFlowController do
  describe "#execute" do
    context "with a valid zip code" do
      before { stub_weather_api_success(zip_code: "10001") }

      it "returns forecast data in response" do
        result = described_class.new(flow_context: { zip_code: "10001", country_code: "us" }).execute

        expect(result[:error]).to be_nil
        expect(result[:response][:zip_code]).to eq("10001")
        expect(result[:response][:current_temperature]).to eq(72.5)
        expect(result[:response][:location]).to eq("New York")
        expect(result[:response][:cached]).to eq(false)
      end

      it "includes extended forecast" do
        result = described_class.new(flow_context: { zip_code: "10001", country_code: "us" }).execute

        expect(result[:response][:extended_forecast]).to be_an(Array)
        expect(result[:response][:extended_forecast].length).to be > 0
      end
    end

    context "with invalid zip code" do
      it "returns error for blank zip code" do
        result = described_class.new(flow_context: { zip_code: "", country_code: "us" }).execute

        expect(result[:error]).to eq("Zip code is required")
        expect(result[:status]).to eq(:bad_request)
      end

      it "returns error for malformed zip code" do
        result = described_class.new(flow_context: { zip_code: "abc", country_code: "us" }).execute

        expect(result[:error]).to match(/5-digit/)
        expect(result[:status]).to eq(:bad_request)
      end
    end

    context "caching behavior" do
      before { stub_weather_api_success(zip_code: "10001") }

      it "caches the result for subsequent requests" do
        first = described_class.new(flow_context: { zip_code: "10001", country_code: "us" }).execute
        second = described_class.new(flow_context: { zip_code: "10001", country_code: "us" }).execute

        expect(first[:response][:cached]).to eq(false)
        expect(second[:response][:cached]).to eq(true)
      end
    end

    context "when location is not found" do
      before { stub_weather_api_not_found(zip_code: "00000") }

      it "returns an error" do
        result = described_class.new(flow_context: { zip_code: "00000", country_code: "us" }).execute

        expect(result[:error]).to include("Could not find location")
        expect(result[:status]).to eq(:unprocessable_entity)
      end
    end
  end
end
