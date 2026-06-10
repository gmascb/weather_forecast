source "https://rubygems.org"

gem "rails", "~> 8.1.3"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"

gem "tzinfo-data", platforms: %i[ windows jruby ]

gem "bootsnap", require: false

gem "rack-cors"
gem "faraday"
gem "flow_subscribers", git: "https://github.com/gmascb/flow_subscribers.git", branch: "master"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false

  gem "rspec-rails"
  gem "rswag-specs"
  gem "webmock"
  gem "factory_bot_rails"
end

group :test do
  gem "shoulda-matchers"
  gem "simplecov", require: false
end

gem "rswag-api"
gem "rswag-ui"
