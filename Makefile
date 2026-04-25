# Little Six Development Makefile
#
# This Makefile provides convenient commands for development tasks.
# All commands delegate to shell scripts in the scripts/ directory.
#
# Usage:
#   make help          - Show this help
#   make website       - Start the marketing website server
#   make game          - Run the Godot game
#   make editor        - Open Godot editor
#   make localstack    - Start LocalStack for local AWS testing
#   make matchmaking   - Run matchmaking service
#   make sam-build     - Build SAM application
#   make sam-api       - Start SAM local API
#   make sam-deploy    - Deploy to AWS
#   make build-site    - Build static website
#   make export-web    - Export Godot game for web
#   make deploy        - Full deployment pipeline
#   make dev-setup     - Start development environment (website + LocalStack)

.PHONY: help website game editor localstack matchmaking sam-build sam-api sam-deploy build-site export-web deploy dev-setup

# Default target
help:
	@echo "Little Six Development Commands"
	@echo "==============================="
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*##"}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

# Development servers
website: ## Start the marketing website server
	@echo "🌐 Starting website server..."
	@./scripts/start-website.sh

game: ## Run the Godot game
	@echo "🎮 Starting Little Six game..."
	@./scripts/run-godot-game.sh

test: ## Run GUT unit tests
	@echo "🧪 Running GUT tests..."
	@./scripts/run-godot-tests.sh

editor: ## Open Godot editor
	@echo "🎨 Opening Godot editor..."
	@./scripts/open-godot-editor.sh

localstack: ## Start LocalStack for local AWS testing
	@echo "☁️  Starting LocalStack..."
	@./scripts/start-localstack.sh

matchmaking: ## Run matchmaking service
	@echo "🎯 Starting matchmaking service..."
	@./scripts/run-matchmaking-service.sh

# SAM/AWS commands
sam-build: ## Build SAM application
	@echo "🔨 Building SAM application..."
	@./scripts/sam-build.sh

sam-api: ## Start SAM local API
	@echo "🌐 Starting SAM local API..."
	@./scripts/sam-local-api.sh

sam-deploy: ## Deploy to AWS
	@echo "🚀 Deploying to AWS..."
	@./scripts/sam-deploy.sh

# Build commands
build-site: ## Build static website
	@echo "🏗️  Building website..."
	@./scripts/build-site.sh

export-web: ## Export Godot game for web
	@echo "🌐 Exporting for web..."
	@./scripts/export-web.sh

# Full deployment
deploy: ## Full deployment pipeline
	@echo "🚀 Starting full deployment..."
	@./scripts/deploy.sh

# Development environment setup
dev-setup: ## Start development environment (website + LocalStack)
	@echo "🛠️  Starting development environment..."
	@echo "🌐 Starting website server in background..."
	@./scripts/start-website.sh &
	@echo "☁️  Starting LocalStack..."
	@./scripts/start-localstack.sh