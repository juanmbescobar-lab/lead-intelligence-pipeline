# Project Plan — Lead Intelligence Pipeline

## Phase 1 — Base Infrastructure
- [x] Professional GitHub repository setup
- [x] Swap configured on EC2 t3.micro
- [ ] CI/CD with GitHub Actions
- [ ] n8n running on EC2 via docker-compose

## Phase 2 — Core Pipeline
- [ ] Web form + webhook trigger
- [ ] LLM node with Claude API (structured JSON output)
- [ ] Branching logic by lead score
- [ ] Email SMTP + SPF/DKIM documentation

## Phase 3 — Reliability + Cost Optimization
- [ ] Layer 1: AWS Cost Explorer script → Telegram alert via n8n
- [ ] Layer 2: Memory limits + docker stats + log rotation
- [ ] Layer 3: ADR-003 + runbook cost section

## Phase 4 — Intentional Failures (Portfolio Differentiator)
- [ ] LLM timeout → fallback to OpenAI
- [ ] Corrupted webhook payload → validation
- [ ] SMTP failure → Telegram alert fallback
- [ ] Memory exhaustion → memory limits in action
- [ ] Each failure → failure-log.md entry with commit link

## Phase 5 — Final Documentation
- [ ] Complete SOP
- [ ] Runbook with cost monitoring section
- [ ] Architecture diagram
- [ ] 5-minute Loom walkthrough
