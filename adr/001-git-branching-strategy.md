# ADR-001: Git Branching Strategy

## Status
Accepted

## Date
2026-03-21

## Context
Project runs n8n on a live EC2 instance (production).
We need a branching strategy that protects production
while allowing active experimentation, including
intentional failures for portfolio documentation.

## Decision
Simplified GitFlow with two permanent branches:
- `main`: stable, always deployable, mirrors production
- `develop`: integration and validation layer

Feature branches are cut from `develop` and merged back
to `develop`. Only verified, stable states are promoted
from `develop` to `main`.

## Consequences
### Positive
- `main` always reflects a deployable state
- Intentional failure experiments stay isolated in `develop`
- Clean, readable commit history on `main`

### Negative
- Extra step in workflow (develop → main promotion)
- Requires discipline to never bypass `develop`

## Alternatives Considered
- **GitHub Flow (main only):** Too risky with a live EC2
  instance. A bad commit would directly break production.
- **Full GitFlow (with release branches):** Overkill for
  a solo portfolio project without versioned releases.
