.PHONY: help setup up down logs health backup test-webhook

help: ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

setup: ## Initial environment setup - copy .env.example to .env
	@test -f .env || (cp .env.example .env && echo "✅ .env created - fill in your credentials")
	@echo "✅ Setup complete"

up: ## Start all services
	docker compose up -d
	@echo "✅ Services started"

down: ## Stop all services
	docker compose down
	@echo "✅ Services stopped"

logs: ## Tail n8n logs
	docker compose logs -f n8n

health: ## Check if n8n is responding
	@curl -s -o /dev/null -w "%{http_code}" http://localhost:5678 | grep -q "200\|401" \
	&& echo "✅ n8n is healthy" \
	|| echo "❌ n8n is not responding"

backup: ## Export n8n workflows to n8n/workflows/
	@echo "📦 Backing up n8n workflows..."
	@mkdir -p n8n/workflows
	@echo "⚠️  Export workflows manually from n8n UI → Settings → Export"

test-webhook: ## Send a test lead payload to the webhook
	@echo "⚠️  Configure WEBHOOK_URL in this target first"

dev-install: ## Install development dependencies
	python3 -m venv .venv
	.venv/bin/pip install -r requirements-dev.txt
	@echo "✅ Dev dependencies installed"
	@echo "👉 Activate with: source .venv/bin/activate"

lint: ## Run all linters locally
	@echo "🔍 Running yamllint..."
	.venv/bin/yamllint .github/workflows/ .yamllint.yml
	@echo "🔍 Running ruff..."
	@if find . -name "*.py" -not -path "./.git/*" -not -path "./.venv/*" | grep -q .; then \
		.venv/bin/ruff check . && .venv/bin/ruff format --check .; \
	else \
		echo "⏭️  No Python files found — skipping Ruff"; \
	fi
	@echo "✅ All linters passed"
