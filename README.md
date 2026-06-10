# Weather Forecast API

REST API that retrieves weather forecast data based on a US zip code. Built with Ruby on Rails 8.

## Stack

- Ruby 3.3.6
- Rails 8.1.3 (API mode)
- PostgreSQL 16
- RSpec + rswag for tests and API docs
- Docker / Docker Compose
- [Open-Meteo](https://open-meteo.com/) for weather data (free, no API key required)

## How it works

The API takes a single required input — a **5-digit US zip code** — plus an optional **region** (`country_code`, defaulting to `us`). From that, it resolves the location's coordinates and returns the weather data for it:

- Current temperature, feels like, min/max, humidity
- Weather description
- 5-day extended forecast (grouped by day)
- A `cached` flag to indicate if the response came from cache

Results are cached in memory for **30 minutes** by zip code. So a repeated request for the same zip code within that window hits the cache instead of calling the weather provider again.

I chose Open-Meteo because it's completely free, open-source, and requires no API key — anyone can clone and run the project instantly.

## Getting the code

```bash
git clone https://github.com/gmascb/weather_forecast.git
cd weather_forecast
```

**Prerequisites (local only):** Ruby 3.3.6 and PostgreSQL running locally. If you use Docker, you only need Docker / Docker Compose installed.

Once cloned, use the Make commands below to run the project. The API will be available at `http://localhost:3000/api-docs/index.html`.

## Make commands

All the commands needed to run the project are wrapped in the `Makefile`. Run `make help` to see them at any time. Below is the full reference, split by environment.

### Local (terminal)

| Command              | What it does                                                  |
| -------------------- | ------------------------------------------------------------- |
| `make setup`         | Install dependencies and prepare the database                 |
| `make start`         | Start the Rails server                                        |
| `make stop`          | Stop the Rails server (kill Puma)                             |
| `make restart`       | Restart the Rails server                                      |
| `make test`          | Run the test suite                                            |
| `make test-coverage` | Run tests with coverage report                                |
| `make console`       | Open the Rails console                                        |
| `make db-create`     | Create the database                                           |
| `make db-migrate`    | Run pending migrations                                        |
| `make db-reset`      | Drop, create, and migrate the database                        |
| `make swagger`       | Regenerate Swagger/OpenAPI docs, start the server open the UI |
| `make lint`          | Run RuboCop linter                                            |

**Quickest way to run locally:**

```bash
make setup    # installs deps and prepares the database
make start    # starts the Rails server at http://localhost:3000
```

### Docker

| Command                  | What it does                                                       |
| ------------------------ | ------------------------------------------------------------------ |
| `make docker-build`      | Build Docker images                                                |
| `make docker-up`         | Start all containers (detached)                                    |
| `make docker-down`       | Stop and remove containers                                         |
| `make docker-restart`    | Restart all containers                                             |
| `make docker-test`       | Run the test suite inside Docker                                   |
| `make docker-console`    | Open the Rails console inside Docker                               |
| `make docker-db-create`  | Create the database inside Docker                                  |
| `make docker-db-migrate` | Run pending migrations inside Docker                               |
| `make docker-db-reset`   | Drop, create, and migrate database inside Docker                   |
| `make docker-swagger`    | Regenerate Swagger docs inside Docker, start the server and open the UI |
| `make docker-lint`       | Run RuboCop inside Docker                                          |
| `make docker-logs`       | Tail logs from all containers                                      |

**Quickest way to run with Docker:**

Make sure your Docker App is running.

```bash
make docker-up    # spins up PostgreSQL + the Rails app at http://localhost:3000
```

## API Documentation

Swagger UI is available at: `http://localhost:3000/api-docs`

The docs are generated from the rswag integration specs, so they're always in sync with the actual API behavior.

## Usage

```bash
# basic request
curl "http://localhost:3000/api/v1/forecast?zip_code=10001"

# optional region (defaults to "us")
curl "http://localhost:3000/api/v1/forecast?zip_code=10001&country_code=us"

# the second call to the same zip code will return cached: true
curl "http://localhost:3000/api/v1/forecast?zip_code=10001"
```

## Architecture decisions V1 - Service + Client

I went with a service-oriented approach. The controller is thin — it only handles the HTTP layer (params, response codes). The business logic lives in two services:

- **Weather::Service**: orchestrates the flow — extracts zip code, checks cache, calls the client, builds the response.
- **Weather::Client**: wraps the Open-Meteo API calls (geocoding + forecast) using Faraday. Translates WMO weather codes into human-readable descriptions.

I used `Rails.cache` with memory store for caching. 
In production we should swap this for Redis, but for this exercise memory store keeps things simple and avoids extra dependencies.

The zip code is validated with a simple regex that accepts exactly 5 digits (US format). If we needed international support, I'd probably accept different formats and rely on the geocoding service to resolve each region.


## Architecture decisions V2 - Flow Subscribers

For V2 I refactored the flow using the [`flow_subscribers`](https://github.com/gmascb/flow_subscribers) gem, which enforces a SOLID-oriented design. Instead of two large services, the logic is broken into small, single-responsibility **flow subscribers**, each doing exactly one thing (validate the zip code, check the cache, geocode the location, fetch the weather, build the response, write the cache).

These subscribers are orchestrated by a `SimpleFlowController` (`Flow::Forecast::ForecastFlowController`), which runs them sequentially. Each subscriber's `execute` method is kept short (~20 lines max) — if it grows, it gets split into another subscriber. This keeps every unit small, testable, and easy to reason about (Single Responsibility and Open/Closed in practice).

Data is shared between steps through a single mutable `flow_context` hash that is passed from one subscriber to the next. A step writes its output to the context (e.g. `flow_context[:latitude]`), and the following steps read from it. Steps short-circuit by checking flags like `flow_context[:error]` or `flow_context[:from_cache]`, so a cache hit or an earlier failure simply skips the remaining work.

All subscribers extend `SimpleCatchFlowSubscriber`, so each one has its own `catch` hook. We use it to log failures with `Rails.logger.error` and translate them into a proper HTTP status, while `Rails.logger.info` traces each step of the flow for observability. The reusable WMO code-to-description mapping lives in a shared `Helpers::WmoDescriptions` module so both V1 and V2 use the same source of truth.

## Challenges

The main challenge was understanding the third-party API integrations. Open-Meteo splits the work across two separate endpoints (geocoding to turn a zip code into coordinates, then forecast to get the weather), so it took some time to map out the two-step flow. On top of that, the forecast endpoint returns numeric WMO weather codes instead of readable descriptions, so I had to dig through the documentation, interpret those codes, and build a consistent mapping table to translate them into human-friendly text in a standardized way across both API versions.

## What I'd improve with more time

- Add Redis for caching in production
- Improve the API's flexibility by letting clients choose the output (e.g. Celsius instead of Fahrenheit) and tailoring the response to how the application consumes it
- Support zip codes from anywhere in the world, making the API location-agnostic instead of US-only
- Rate limiting on the endpoint
- Add pagination or date range params for the extended forecast
- CI/CD pipeline setup via github actions
