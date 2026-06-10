require "rails_helper"

RSpec.describe Flow::Forecast::Subscribers::ValidateZipCodeFlowSubscriber do
  subject(:subscriber) { described_class.new }

  describe "#execute" do
    it "passes with valid 5-digit zip code" do
      context = { zip_code: "10001" }
      subscriber.execute(context)

      expect(context[:error]).to be_nil
    end

    it "sets error when zip code is blank" do
      context = { zip_code: "" }
      subscriber.execute(context)

      expect(context[:error]).to eq("Zip code is required")
      expect(context[:status]).to eq(:bad_request)
    end

    it "sets error when zip code is nil" do
      context = { zip_code: nil }
      subscriber.execute(context)

      expect(context[:error]).to eq("Zip code is required")
      expect(context[:status]).to eq(:bad_request)
    end

    it "sets error when zip code has wrong format" do
      context = { zip_code: "123" }
      subscriber.execute(context)

      expect(context[:error]).to match(/5-digit/)
      expect(context[:status]).to eq(:bad_request)
    end

    it "sets error when zip code contains letters" do
      context = { zip_code: "abcde" }
      subscriber.execute(context)

      expect(context[:error]).to match(/5-digit/)
      expect(context[:status]).to eq(:bad_request)
    end
  end

  describe "#catch" do
    it "logs error and sets internal server error" do
      context = { zip_code: "10001" }
      subscriber.catch(StandardError.new("unexpected"), context)

      expect(context[:error]).to eq("Validation failed unexpectedly")
      expect(context[:status]).to eq(:internal_server_error)
    end
  end
end
