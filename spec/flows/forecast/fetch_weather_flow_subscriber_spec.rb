require "rails_helper"

RSpec.describe Flow::Forecast::Subscribers::FetchWeatherFlowSubscriber do
  subject(:subscriber) { described_class.new }

  describe "#execute" do
    it "skips when there is an error" do
      context = { latitude: 40.71, longitude: -74.00, error: "some error" }
      subscriber.execute(context)

      expect(context[:raw_weather]).to be_nil
    end

    it "skips when response is from cache" do
      context = { latitude: 40.71, longitude: -74.00, from_cache: true }
      subscriber.execute(context)

      expect(context[:raw_weather]).to be_nil
    end

    it "fetches weather data and stores in context" do
      stub_weather_api_success(zip_code: "10001")
      context = { latitude: 40.71427, longitude: -74.00597 }
      subscriber.execute(context)

      expect(context[:raw_weather]).to be_a(Hash)
      expect(context[:raw_weather][:current][:temperature_2m]).to eq(72.5)
    end
  end

  describe "#catch" do
    it "logs error and sets service unavailable" do
      context = {}
      subscriber.catch(Faraday::TimeoutError.new("timeout"), context)

      expect(context[:error]).to eq("Weather service is temporarily unavailable")
      expect(context[:status]).to eq(:service_unavailable)
    end
  end
end
