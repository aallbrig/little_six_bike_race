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
dev: ## Start complete development stack (matchmaking + website)
	@echo "🚀 Starting Little Six Development Stack..."
	@echo ""
	@echo "📋 Services that will be started:"
	@echo "   • Matchmaking service (Node.js API)"
	@echo "   • Marketing website (static server)"
	@echo "   • LocalStack (optional - run 'make localstack' separately)"
	@echo ""
	@echo "⚠️  Make sure Node.js is installed"
	@echo "💡 For full AWS simulation, run: make localstack"
	@echo ""
	@echo "🛑 Press Ctrl+C to stop all services"
	@echo ""
	@echo "🌐 URLs when ready:"
	@echo "   • Matchmaking API:      http://localhost:3001"
	@echo "   • Marketing Website:    http://localhost:8000"
	@echo "   • Godot Game:           make game"
	@echo "   • LocalStack (optional): http://localhost:4566"
	@echo ""
	@echo "🎯 Starting services..."
	@echo ""
	@echo "🎯 1/2 Starting matchmaking service..."
	@USE_DYNAMODB=false ./scripts/run-matchmaking-service.sh &
	@echo "⏳ Waiting for matchmaking to start..."
	@sleep 5
	@echo ""
	@echo "🌐 2/2 Starting website..."
	@./scripts/start-website.sh &
	@echo "⏳ Waiting for website to start..."
	@sleep 2
	@echo ""
	@echo "✅ Core services started!"
	@echo ""
	@echo "🌐 Development URLs:"
	@echo "   • Matchmaking API:      http://localhost:3001/matchmaking/find"
	@echo "   • Marketing Website:    http://localhost:8000"
	@echo "   • Play Game:            make game"
	@echo "   • LocalStack (if running): http://localhost:4566"
	@echo ""
	@echo "🧪 Test the stack:"
	@echo "   1. Check API: curl http://localhost:3001/health"
	@echo "   2. Open website: http://localhost:8000"
	@echo "   3. Play game: make game"
	@echo ""
	@echo "🔄 Services are running in background."
	@echo "🛑 Use 'pkill -f \"node\|python\"' to stop services"
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