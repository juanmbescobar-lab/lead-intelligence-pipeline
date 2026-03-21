# ADR-003: CD via direct SSH to EC2

## Status
Accepted

## Date
2026-03-21

## Context
GitHub Actions needs to deploy to EC2 automatically on
every merge to develop. Two approaches were evaluated.

## Decision
Use direct SSH from GitHub Actions runner to EC2.
SSH private key stored as GitHub Secret (EC2_SSH_KEY).

## Consequences
### Positive
- Simple to implement and debug
- No additional infrastructure needed
- Standard approach for small/medium projects

### Negative
- EC2 port 22 must be open to GitHub Actions IP ranges
- SSH key rotation requires updating GitHub Secret manually

## Alternatives Considered
- **Self-hosted runner on EC2:** More secure (no inbound port
  needed) but adds operational complexity — the runner agent
  itself needs monitoring and maintenance.

## Security Mitigations
- SSH key stored only as GitHub Secret, never in code
- EC2 Security Group restricts port 22 to known IPs only
- Deploy user has minimal required permissions
