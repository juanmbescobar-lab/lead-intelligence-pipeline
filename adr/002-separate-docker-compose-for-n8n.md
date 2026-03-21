# ADR-002: Separate docker-compose for n8n

## Status
Accepted

## Date
2026-03-21

## Context
EC2 instance already runs InvoiceTrack via Docker.
We need to deploy n8n as a second service on the same server.

## Decision
Run n8n in its own docker-compose.yml under a separate
directory (/home/ubuntu/lead-intelligence/) instead of
adding it to InvoiceTrack's compose file.

## Consequences
### Positive
- Service isolation: n8n failure doesn't affect InvoiceTrack
- Independent lifecycle: start/stop/update each service separately
- Cleaner separation of concerns between projects

### Negative
- Two compose files to maintain on the server
- No shared Docker network by default (can be added explicitly if needed)

## Alternatives Considered
- **Single compose file:** Simpler but creates tight coupling.
  A misconfigured n8n volume could bring down InvoiceTrack.
