require "rails_helper"

RSpec.describe Flow::Forecast::Subscribers::CheckCacheFlowSubscriber do
  subject(:subscriber) { described_class.new }

  describe "#execute" do
    it "skips when there is an error" do
      context = { zip_code: "10001", error: "some error" }
      subscriber.execute(context)

      expect(context[:from_cache]).to be_nil
    end

    it "sets from_cache when data is cached" do
      cached_data = { zip_code: "10001", location: "New York", current_temperature: 72.5 }
      Rails.cache.write("forecast_v2_10001", cached_data, expires_in: 30.minutes)

      context = { zip_code: "10001" }
      subscriber.execute(context)

      expect(context[:from_cache]).to eq(true)
      expect(context[:response][:cached]).to eq(true)
      expect(context[:response][:location]).to eq("New York")
    end

    it "does nothing when cache is empty" do
      context = { zip_code: "10001" }
      subscriber.execute(context)

      expect(context[:from_cache]).to be_nil
      expect(context[:response]).to be_nil
    end
  end

  describe "#catch" do
    it "logs error and allows flow to continue" do
      context = { zip_code: "10001" }
      subscriber.catch(StandardError.new("Redis down"), context)

      expect(context[:from_cache]).to eq(false)
      expect(context[:error]).to be_nil
    end
  end
end
