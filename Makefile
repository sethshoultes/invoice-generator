# Invoice Generator - Development Commands

.PHONY: help start stop restart logs build clean test

help: ## Show this help message
	@echo "Invoice Generator - Available Commands"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""

start: ## Start all services
	@./start-dev.sh

stop: ## Stop all services
	@./stop-dev.sh

restart: ## Restart all services
	@docker-compose restart

restart-backend: ## Restart backend only
	@docker-compose restart backend

restart-frontend: ## Restart frontend only
	@docker-compose restart frontend

logs: ## View logs from all services
	@docker-compose logs -f

logs-backend: ## View backend logs only
	@docker-compose logs -f backend

logs-frontend: ## View frontend logs only
	@docker-compose logs -f frontend

logs-db: ## View database logs only
	@docker-compose logs -f db

build: ## Build all Docker images
	@docker-compose build

build-backend: ## Build backend image only
	@docker-compose build backend

build-frontend: ## Build frontend image only
	@docker-compose build frontend

clean: ## Stop services and remove volumes (WARNING: deletes data)
	@echo "WARNING: This will delete all data!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker-compose down -v; \
		echo "All services and data removed."; \
	fi

reset: clean start ## Clean everything and restart fresh

ps: ## Show running containers
	@docker-compose ps

shell-backend: ## Open shell in backend container
	@docker-compose exec backend /bin/bash

shell-frontend: ## Open shell in frontend container
	@docker-compose exec frontend /bin/sh

shell-db: ## Connect to PostgreSQL database
	@docker-compose exec db psql -U postgres

test: ## Run backend tests
	@docker-compose exec backend pytest -v

env: ## Create .env from .env.example
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "Created .env file from .env.example"; \
		echo "Please review and update the values."; \
	else \
		echo ".env file already exists"; \
	fi

health: ## Check health of all services
	@echo "Checking service health..."
	@echo ""
	@echo -n "Frontend (3002): "
	@curl -s -o /dev/null -w "%{http_code}" http://localhost:3002 | grep -q 200 && echo "✓ OK" || echo "✗ FAIL"
	@echo -n "Backend (8002):  "
	@curl -s -o /dev/null -w "%{http_code}" http://localhost:8002/health | grep -q 200 && echo "✓ OK" || echo "✗ FAIL"
	@echo -n "Studio (3003):   "
	@curl -s -o /dev/null -w "%{http_code}" http://localhost:3003 | grep -q 200 && echo "✓ OK" || echo "✗ FAIL"
	@echo -n "Database (5435): "
	@docker-compose exec -T db pg_isready -U postgres > /dev/null 2>&1 && echo "✓ OK" || echo "✗ FAIL"
