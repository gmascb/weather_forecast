require "rails_helper"

RSpec.describe Flow::Forecast::Subscribers::GeocodeLocationFlowSubscriber do
  subject(:subscriber) { described_class.new }

  describe "#execute" do
    it "skips when there is an error" do
      context = { zip_code: "10001", country_code: "us", error: "some error" }
      subscriber.execute(context)

      expect(context[:latitude]).to be_nil
    end

    it "skips when response is from cache" do
      context = { zip_code: "10001", country_code: "us", from_cache: true }
      subscriber.execute(context)

      expect(context[:latitude]).to be_nil
    end

    it "sets coordinates when location is found" do
      stub_weather_api_success(zip_code: "10001")
      context = { zip_code: "10001", country_code: "us" }
      subscriber.execute(context)

      expect(context[:latitude]).to eq(40.71427)
      expect(context[:longitude]).to eq(-74.00597)
      expect(context[:location_name]).to eq("New York")
    end

    it "sets error when location is not found" do
      stub_weather_api_not_found(zip_code: "00000")
      context = { zip_code: "00000", country_code: "us" }
      subscriber.execute(context)

      expect(context[:error]).to include("Could not find location")
      expect(context[:status]).to eq(:unprocessable_entity)
    end
  end

  describe "#catch" do
    it "logs error and sets service unavailable" do
      context = { zip_code: "10001" }
      subscriber.catch(Faraday::TimeoutError.new("timeout"), context)

      expect(context[:error]).to eq("Weather service is temporarily unavailable")
      expect(context[:status]).to eq(:service_unavailable)
    end
  end
end
