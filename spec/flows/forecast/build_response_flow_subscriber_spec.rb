require "rails_helper"

RSpec.describe Flow::Forecast::Subscribers::BuildResponseFlowSubscriber do
  subject(:subscriber) { described_class.new }

  let(:raw_weather) do
    {
      current: {
        temperature_2m: 72.5,
        relative_humidity_2m: 55,
        apparent_temperature: 70.1,
        weather_code: 0
      },
      daily: {
        time: %w[2025-06-10 2025-06-11 2025-06-12],
        temperature_2m_max: [76.0, 72.0, 67.0],
        temperature_2m_min: [68.0, 70.0, 65.0],
        weather_code: [1, 2, 61]
      }
    }
  end

  describe "#execute" do
    it "skips when there is an error" do
      context = { error: "some error", raw_weather: raw_weather }
      subscriber.execute(context)

      expect(context[:response]).to be_nil
    end

    it "skips when response is from cache" do
      context = { from_cache: true, raw_weather: raw_weather }
      subscriber.execute(context)

      expect(context[:response]).to be_nil
    end

    it "builds response with current weather" do
      context = { zip_code: "10001", location_name: "New York", raw_weather: raw_weather }
      subscriber.execute(context)

      response = context[:response]
      expect(response[:zip_code]).to eq("10001")
      expect(response[:location]).to eq("New York")
      expect(response[:current_temperature]).to eq(72.5)
      expect(response[:feels_like]).to eq(70.1)
      expect(response[:humidity]).to eq(55)
      expect(response[:description]).to eq("clear sky")
      expect(response[:cached]).to eq(false)
    end

    it "builds extended forecast" do
      context = { zip_code: "10001", location_name: "New York", raw_weather: raw_weather }
      subscriber.execute(context)

      forecast = context[:response][:extended_forecast]
      expect(forecast.length).to eq(3)
      expect(forecast.first[:date]).to eq("2025-06-10")
      expect(forecast.first[:temp_max]).to eq(76.0)
      expect(forecast.first[:description]).to eq("mainly clear")
    end
  end

  describe "#catch" do
    it "logs error and sets internal server error" do
      context = { zip_code: "10001" }
      subscriber.catch(StandardError.new("nil data"), context)

      expect(context[:error]).to eq("Failed to process weather data")
      expect(context[:status]).to eq(:internal_server_error)
    end
  end
end
