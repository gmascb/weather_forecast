.PHONY: help setup start stop restart test test-coverage console db-create db-migrate db-reset \
       swagger lint \
       docker-build docker-up docker-down docker-restart docker-test docker-console \
       docker-db-create docker-db-migrate docker-db-reset docker-swagger docker-lint docker-logs

APP_NAME = weather-forecast-api
DC = docker compose
API_DOCS_URL = http://localhost:3000/api-docs

# Open a URL in the machine's default browser (macOS: open, Linux: xdg-open).
define open_browser
	@(command -v open >/dev/null 2>&1 && open "$(API_DOCS_URL)") || \
	 (command -v xdg-open >/dev/null 2>&1 && xdg-open "$(API_DOCS_URL)") || \
	 echo "Swagger UI available at $(API_DOCS_URL)"
endef

# Poll the server until it accepts connections (timeout ~30s).
define wait_for_server
	@echo "Waiting for $(API_DOCS_URL) ..."
	@for i in $$(seq 1 30); do \
		curl -s -o /dev/null "$(API_DOCS_URL)" && exit 0; \
		sleep 1; \
	done; \
	echo "Server did not respond in time; open $(API_DOCS_URL) manually."
endef

help: ## Show available commands
	@echo ""
	@echo "$(APP_NAME) — available commands"
	@echo ""
	@echo "Local (terminal):"
	@grep -E '^[a-z]([a-z0-9_-]+)?:.*##' $(MAKEFILE_LIST) | grep -v '^docker-' | \
		awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Docker:"
	@grep -E '^docker-[a-z]([a-z0-9_-]+)?:.*##' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'
	@echo ""

# ---------------------------------------------------------------------------
# Local (terminal)
# ---------------------------------------------------------------------------

setup: ## Install dependencies and prepare the database
	bundle install
	rails db:prepare

start: ## Start the Rails server
	rails server

stop: ## Stop the Rails server (kill Puma)
	@if [ -f tmp/pids/server.pid ]; then \
		kill -9 $$(cat tmp/pids/server.pid) 2>/dev/null; \
		rm -f tmp/pids/server.pid; \
		echo "Server stopped."; \
	else \
		echo "No server PID file found."; \
	fi

restart: stop start ## Restart the Rails server

test: ## Run the test suite
	bundle exec rspec

test-coverage: ## Run tests with coverage report
	COVERAGE=true bundle exec rspec

console: ## Open the Rails console
	rails console

db-create: ## Create the database
	rails db:create

db-migrate: ## Run pending migrations
	rails db:migrate

db-reset: ## Drop, create, and migrate the database
	rails db:reset

swagger: ## Regenerate Swagger/OpenAPI docs, start the server and open the UI
	bundle exec rake rswag:specs:swaggerize
	@if ! curl -s -o /dev/null "$(API_DOCS_URL)"; then \
		echo "Starting Rails server in background ..."; \
		nohup rails server >/dev/null 2>&1 & \
	fi
	$(call wait_for_server)
	$(call open_browser)

lint: ## Run RuboCop linter
	bundle exec rubocop

# ---------------------------------------------------------------------------
# Docker
# ---------------------------------------------------------------------------

docker-build: ## Build Docker images
	$(DC) build

docker-up: ## Start all containers (detached)
	$(DC) up -d --build

docker-down: ## Stop and remove containers
	$(DC) down

docker-restart: docker-down docker-up ## Restart all containers

docker-test: ## Run the test suite inside Docker
	$(DC) run --rm -e RAILS_ENV=test web bash -c "rails db:prepare && bundle exec rspec"

docker-console: ## Open the Rails console inside Docker
	$(DC) run --rm web rails console

docker-db-create: ## Create the database inside Docker
	$(DC) run --rm web rails db:create

docker-db-migrate: ## Run pending migrations inside Docker
	$(DC) run --rm web rails db:migrate

docker-db-reset: ## Drop, create, and migrate database inside Docker
	$(DC) run --rm web rails db:reset

docker-swagger: ## Regenerate Swagger docs inside Docker, start the server and open the UI
	$(DC) run --rm web bundle exec rake rswag:specs:swaggerize
	$(DC) up -d
	$(call wait_for_server)
	$(call open_browser)

docker-lint: ## Run RuboCop inside Docker
	$(DC) run --rm web bundle exec rubocop

docker-logs: ## Tail logs from all containers
	$(DC) logs -f
