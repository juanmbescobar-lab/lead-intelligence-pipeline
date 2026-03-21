# Lead Intelligence Pipeline

Automated lead capture, enrichment, and triage system built with n8n, Claude AI, and Docker.

## Architecture

Webhook → n8n → LLM Enrichment → Scoring → Routing → Notification

## Stack

- **Automation:** n8n (self-hosted)
- **AI:** Claude (Anthropic) with OpenAI fallback
- **Infrastructure:** AWS EC2 + Docker
- **Notifications:** Telegram
- **Storage:** Google Sheets / Airtable

## Quick Start
```bash
cp .env.example .env
# Fill in your credentials in .env
make setup
make up
```

## Documentation

- [Architecture Decisions](adr/)
- [Runbook](docs/runbook.md)
- [Failure Log](docs/failure-log.md)
- [Troubleshooting](docs/troubleshooting.md)
