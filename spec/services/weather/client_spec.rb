require "rails_helper"

RSpec.describe Weather::Client do
  let(:client) { described_class.new }

  describe "#forecast" do
    context "when API responds successfully" do
      before { stub_weather_api_success(zip_code: "10001") }

      it "returns current weather data" do
        result = client.forecast("10001")

        expect(result[:current][:name]).to eq("New York")
        expect(result[:current][:temp]).to eq(72.5)
        expect(result[:current][:humidity]).to eq(55)
      end

      it "returns forecast data grouped by day" do
        result = client.forecast("10001")

        expect(result[:forecast]).to be_an(Array)
        result[:forecast].each do |day|
          expect(day).to include(:date, :temp_min, :temp_max, :description)
        end
      end
    end

    context "when zip code is not found" do
      before { stub_weather_api_not_found(zip_code: "00000") }

      it "returns an error hash" do
        result = client.forecast("00000")

        expect(result[:error]).to be_present
      end
    end
  end
end
