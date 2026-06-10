require "rails_helper"

RSpec.describe Flow::Forecast::Subscribers::WriteCacheFlowSubscriber do
  subject(:subscriber) { described_class.new }

  describe "#execute" do
    it "skips when there is an error" do
      context = { zip_code: "10001", error: "some error", response: { zip_code: "10001" } }
      subscriber.execute(context)

      expect(Rails.cache.read("forecast_v2_10001")).to be_nil
    end

    it "skips when response came from cache" do
      context = { zip_code: "10001", from_cache: true, response: { zip_code: "10001" } }
      subscriber.execute(context)

      expect(Rails.cache.read("forecast_v2_10001")).to be_nil
    end

    it "writes response to cache without cached flag" do
      response_data = { zip_code: "10001", location: "New York", cached: false }
      context = { zip_code: "10001", response: response_data }
      subscriber.execute(context)

      cached = Rails.cache.read("forecast_v2_10001")
      expect(cached[:zip_code]).to eq("10001")
      expect(cached[:location]).to eq("New York")
      expect(cached).not_to have_key(:cached)
    end
  end

  describe "#catch" do
    it "logs error and does not break the flow" do
      context = { zip_code: "10001", response: { zip_code: "10001" } }
      subscriber.catch(StandardError.new("Redis down"), context)

      expect(context[:error]).to be_nil
    end
  end
end
