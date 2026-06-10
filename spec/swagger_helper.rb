require "rails_helper"

RSpec.configure do |config|
  config.openapi_root = Rails.root.join("swagger").to_s

  config.openapi_specs = {
    "v1/swagger.yaml" => {
      openapi: "3.0.1",
      info: {
        title: "Weather Forecast API",
        version: "v1",
        description: "API for retrieving current weather and 5-day forecast by US zip code. Uses Open-Meteo as the weather data provider."
      },
      paths: {},
      servers: [
        {
          url: "http://localhost:3000",
          description: "Local development"
        }
      ]
    },
    "v2/swagger.yaml" => {
      openapi: "3.0.1",
      info: {
        title: "Weather Forecast API",
        version: "v2",
        description: "API V2 using FlowSubscribers pattern for organized business logic. Returns current weather and 5-day forecast by US zip code."
      },
      paths: {},
      servers: [
        {
          url: "http://localhost:3000",
          description: "Local development"
        }
      ]
    }
  }

  config.openapi_format = :yaml
end
