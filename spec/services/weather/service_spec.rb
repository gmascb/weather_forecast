require "rails_helper"

RSpec.describe Weather::Service do
  describe "#call" do
    context "with a valid zip code" do
      it "returns forecast data" do
        stub_weather_api_success(zip_code: "10001")
        result = described_class.new("10001").call

        expect(result[:zip_code]).to eq("10001")
        expect(result[:current_temperature]).to eq(72.5)
        expect(result[:location]).to eq("New York")
        expect(result[:description]).to eq("clear sky")
        expect(result[:cached]).to eq(false)
      end

      it "returns extended forecast" do
        stub_weather_api_success(zip_code: "10001")
        result = described_class.new("10001").call

        expect(result[:extended_forecast]).to be_an(Array)
        expect(result[:extended_forecast].length).to be > 0
        expect(result[:extended_forecast].first).to include(:date, :temp_min, :temp_max, :description)
      end
    end

    context "validation" do
      it "returns error when zip code is blank" do
        result = described_class.new("").call

        expect(result[:error]).to eq("Zip code is required")
        expect(result[:status]).to eq(:bad_request)
      end

      it "returns error when zip code is nil" do
        result = described_class.new(nil).call

        expect(result[:error]).to eq("Zip code is required")
        expect(result[:status]).to eq(:bad_request)
      end

      it "returns error when zip code has wrong format" do
        result = described_class.new("123").call

        expect(result[:error]).to match(/5-digit/)
        expect(result[:status]).to eq(:bad_request)
      end

      it "returns error when zip code contains letters" do
        result = described_class.new("abcde").call

        expect(result[:error]).to match(/5-digit/)
        expect(result[:status]).to eq(:bad_request)
      end
    end

    context "caching behavior" do
      it "caches the result for subsequent requests" do
        stub_weather_api_success(zip_code: "10001")

        first_call = described_class.new("10001").call
        second_call = described_class.new("10001").call

        expect(first_call[:cached]).to eq(false)
        expect(second_call[:cached]).to eq(true)
      end

      it "returns same data from cache" do
        stub_weather_api_success(zip_code: "10001")

        first_call = described_class.new("10001").call
        second_call = described_class.new("10001").call

        expect(second_call[:current_temperature]).to eq(first_call[:current_temperature])
        expect(second_call[:location]).to eq(first_call[:location])
      end
    end

    context "when the weather API returns an error" do
      it "returns the error message with unprocessable_entity status" do
        stub_weather_api_not_found(zip_code: "00000")
        result = described_class.new("00000").call

        expect(result[:error]).to be_present
        expect(result[:status]).to eq(:unprocessable_entity)
      end
    end
  end
end
