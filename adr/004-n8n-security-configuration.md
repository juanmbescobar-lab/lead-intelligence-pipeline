# ADR-004: n8n Security Configuration

## Status
Accepted

## Date
2026-03-22

## Context
n8n instance will have access to production API keys
(Claude, OpenAI, Telegram). Needs authentication and
access control before being exposed on a public IP.

## Decision
- Basic auth enabled with strong generated password
- Accessible from any IP (not restricted to single IP)
- Port 5678 open in EC2 Security Group

## Consequences
### Positive
- Accessible from any device/location
- Simple to configure and maintain
- No IP change issues with domestic internet

### Negative
- Port 5678 exposed to internet — mitigated by basic auth
- No HTTPS yet — credentials travel unencrypted

## Future Improvements
- Add Nginx reverse proxy with HTTPS (Let's Encrypt)
- Restrict port 5678 and expose only via 443
- This will be addressed in a future PR

## Alternatives Considered
- **IP restriction:** Rejected — domestic IP changes frequently
- **VPN:** Rejected — adds operational complexity for current phase
