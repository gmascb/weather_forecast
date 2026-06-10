module WeatherApiHelpers
  def stub_weather_api_success(zip_code: "10001")
    geocoding_response = {
      results: [
        { id: 5128581, name: "New York", latitude: 40.71427, longitude: -74.00597,
          country_code: "US", country: "United States", admin1: "New York" }
      ]
    }

    forecast_response = {
      latitude: 40.71,
      longitude: -74.01,
      current_units: { temperature_2m: "°F", relative_humidity_2m: "%", apparent_temperature: "°F" },
      current: {
        temperature_2m: 72.5,
        relative_humidity_2m: 55,
        apparent_temperature: 70.1,
        weather_code: 0
      },
      daily_units: { temperature_2m_max: "°F", temperature_2m_min: "°F" },
      daily: {
        time: [ "2025-06-10", "2025-06-11", "2025-06-12" ],
        temperature_2m_max: [ 76.0, 72.0, 67.0 ],
        temperature_2m_min: [ 68.0, 70.0, 65.0 ],
        weather_code: [ 1, 2, 61 ]
      }
    }

    stub_request(:get, "https://geocoding-api.open-meteo.com/v1/search")
      .with(query: hash_including(name: zip_code))
      .to_return(status: 200, body: geocoding_response.to_json, headers: { "Content-Type" => "application/json" })

    stub_request(:get, "https://api.open-meteo.com/v1/forecast")
      .with(query: hash_including(latitude: "40.71427", longitude: "-74.00597"))
      .to_return(status: 200, body: forecast_response.to_json, headers: { "Content-Type" => "application/json" })
  end

  def stub_weather_api_not_found(zip_code: "00000")
    geocoding_response = { results: nil }

    stub_request(:get, "https://geocoding-api.open-meteo.com/v1/search")
      .with(query: hash_including(name: zip_code))
      .to_return(status: 200, body: geocoding_response.to_json, headers: { "Content-Type" => "application/json" })
  end
end

RSpec.configure do |config|
  config.include WeatherApiHelpers
end
