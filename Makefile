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
#   make dev           - Start complete development stack (LocalStack + matchmaking + website)
#   make dev-setup     - Start development environment (website + LocalStack)
#   make test-stack    - Test local development stack functionality

.PHONY: help website game editor localstack matchmaking sam-build sam-api sam-deploy build-site export-web deploy dev dev-setup test-stack

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
dev: ## Start complete development stack (LocalStack + matchmaking + website)
	@echo "🚀 Starting Little Six Development Stack..."
	@echo ""
	@echo "📋 Services that will be started:"
	@echo "   • LocalStack (AWS simulation)"
	@echo "   • Matchmaking service (Node.js API)"
	@echo "   • Marketing website (static server)"
	@echo ""
	@echo "⚠️  Make sure Docker and Node.js are installed"
	@echo ""
	@echo "🛑 Press Ctrl+C to stop all services"
	@echo ""
	@echo "🌐 URLs when ready:"
	@echo "   • LocalStack Dashboard: http://localhost:4566"
	@echo "   • Matchmaking API:      http://localhost:3001"
	@echo "   • Marketing Website:    http://localhost:8000"
	@echo "   • Godot Game:           make game"
	@echo ""
	@echo "🎯 Starting services..."
	@echo ""
	@echo "☁️  1/3 Starting LocalStack..."
	@./scripts/start-localstack.sh &
	@echo "⏳ Waiting for LocalStack to initialize..."
	@sleep 8
	@echo ""
	@echo "🎯 2/3 Starting matchmaking service..."
	@USE_DYNAMODB=true ./scripts/run-matchmaking-service.sh &
	@echo "⏳ Waiting for matchmaking to start..."
	@sleep 5
	@echo ""
	@echo "🌐 3/3 Starting website..."
	@./scripts/start-website.sh &
	@echo "⏳ Waiting for website to start..."
	@sleep 2
	@echo ""
	@echo "✅ All services started!"
	@echo ""
	@echo "🌐 Development URLs:"
	@echo "   • LocalStack Dashboard: http://localhost:4566"
	@echo "   • Matchmaking API:      http://localhost:3001/matchmaking/find"
	@echo "   • Marketing Website:    http://localhost:8000"
	@echo "   • Play Game:            make game"
	@echo ""
	@echo "🧪 Test the full stack:"
	@echo "   1. Open http://localhost:8000/play/"
	@echo "   2. The game should connect to matchmaking"
	@echo "   3. Check matchmaking logs for API calls"
	@echo ""
	@echo "🔄 Services are running in background."
	@echo "🛑 Use 'pkill -f \"node\|python\|docker\"' to stop all services"
	@echo ""
	@trap 'echo ""; echo "🛑 Stopping services..."; pkill -f "node.*matchmaking\|python.*http\.server\|serve" 2>/dev/null; echo "✅ Services stopped"; exit' INT
	@wait

test-stack: ## Test local development stack functionality
	@echo "🧪 Testing Little Six local development stack..."
	@./scripts/test-local-dev-stack.sh

dev-setup: ## Start development environment (website + LocalStack)
	@echo "🛠️  Starting development environment..."
	@echo "🌐 Starting website server in background..."
	@./scripts/start-website.sh &
	@echo "☁️  Starting LocalStack..."
	@./scripts/start-localstack.sh