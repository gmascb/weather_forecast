module Helpers
  module WmoDescriptions
    CODES = {
      0 => "clear sky", 
      1 => "mainly clear", 
      2 => "partly cloudy", 
      3 => "overcast",
      45 => "foggy", 
      48 => "depositing rime fog",
      51 => "light drizzle", 
      53 => "moderate drizzle", 
      55 => "dense drizzle",
      61 => "slight rain", 
      63 => "moderate rain", 
      65 => "heavy rain",
      71 => "slight snow", 
      73 => "moderate snow", 
      75 => "heavy snow",
      80 => "slight rain showers", 
      81 => "moderate rain showers", 
      82 => "violent rain showers",
      95 => "thunderstorm", 
      96 => "thunderstorm with slight hail", 
      99 => "thunderstorm with heavy hail"
    }.freeze

    def wmo_description(code)
      CODES[code] || "unknown"
    end
  end
end
