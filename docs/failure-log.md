# Failure Log

This document tracks every production failure encountered during this project.
Each entry includes root cause analysis and the exact fix applied.

> "The only real mistake is the one from which we learn nothing." — Henry Ford

---

## PREVENTIVE-001: Swap configured on EC2 t3.micro

**Date:** 2026-03-22
**Type:** Preventive decision — not a failure, prevents one
**Severity:** N/A

### Context
EC2 t3.micro with 914MB RAM running two Docker services:
- InvoiceTrack (~440MB in use)
- n8n (estimated ~200-300MB additional)
Available margin without swap: ~180MB — insufficient for LLM processing spikes.

### Risk without swap
Without swap, a memory spike during LLM processing would trigger the Linux
OOM (Out Of Memory) killer, which silently terminates the most expensive
process — InvoiceTrack or n8n — with no clear error message or alert.

### Solution applied
1GB swapfile at /swapfile, activated and persisted in /etc/fstab.

### Alert signal for the future
If `free -h` shows swap in use consistently → need to optimize memory
or migrate to t3.small (~$17/month vs ~$8/month).

### Commands applied
```bash
sudo fallocate -l 1G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

---

## FAILURE-001: CD Pipeline — Directory Not Found on EC2

**Date:** 2026-03-22
**Severity:** High — CD pipeline completely broken
**Detected by:** GitHub Actions — Deploy to EC2 step failed

### What broke
The CD pipeline ran automatically after merging to main and failed
on the deploy step. n8n was never started.

### Error message
```
bash: cd: /home/ubuntu/lead-intelligence: No such file or directory
```

### How we detected it
- GitHub Actions marked the Deploy step as ❌
- Telegram notification arrived in Lead Intelligence Alerts group
- Confirmed the Telegram alert system was working correctly

### Why it happened
The CD workflow assumes ~/lead-intelligence/ exists on the EC2 and runs:
```bash
cd ~/lead-intelligence && git pull origin develop && docker compose up -d
```
This was the first deployment — the directory had never been created.
Classic bootstrap problem: the automation that sets up the environment
cannot run before the environment exists.

### What we changed
One-time manual bootstrap on the EC2:
```bash
mkdir ~/lead-intelligence
cd ~/lead-intelligence
git clone git@github.com:juanmbescobar-lab/lead-intelligence-pipeline.git .
```

### What we learned
First-time server setup (bootstrapping) cannot be automated by the same
CD pipeline that depends on that setup. Always document one-time manual
steps required before automation takes over. Added to runbook.

---

## FAILURE-002: n8n Permission Denied on Volume Mount

**Date:** 2026-03-22
**Severity:** Critical — n8n crashed in infinite restart loop
**Detected by:** `docker ps` showed STATUS: Restarting (1)

### What broke
After running `docker compose up -d`, n8n entered a crash/restart loop
and never reached a running state. Port 5678 was never exposed.

### Error message
```
No encryption key found - Auto-generating and saving to: /home/node/.n8n/config
Error: EACCES: permission denied, open '/home/node/.n8n/config'
[repeated hundreds of times]
```

### How we detected it
```bash
docker ps
# STATUS: Restarting (1) 46 seconds ago  ← no port mapping visible

docker logs n8n
# EACCES: permission denied on every line
```

### Why it happened
The docker-compose.yml mounts ./n8n-data (host) into /home/node/.n8n (container).
The n8n-data/ directory was created by user ubuntu on the host.
Inside the container, n8n runs as user node with UID 1000.

Linux enforces permissions by UID. The host directory was owned by ubuntu,
not by UID 1000 in the context the container expected — so n8n could not
write its encryption key config file.

Key concept: bind mounts are live mirrors, not copies. Permissions on the
host directory are enforced by the Linux kernel for all processes,
including those inside containers.

### What we changed
```bash
sudo chown -R 1000:1000 ~/lead-intelligence/n8n-data/
docker restart n8n
```

### Verification
```bash
docker ps
# STATUS: Up 2 minutes (healthy)  ✅
```

### What we learned
Always verify the UID of the process running inside a container before
mounting a host directory. For n8n, the official image runs as user node
with UID 1000. The chown command is now part of the deployment runbook
as a required step for any fresh installation.

---

## FAILURE-003: Port 5678 Connection Timeout

**Date:** 2026-03-22
**Severity:** High — n8n internally healthy but externally unreachable
**Detected by:** Browser — ERR_CONNECTION_TIMED_OUT

### What broke
After confirming n8n was healthy internally (docker ps showed healthy),
accessing http://15.134.33.226:5678 returned a connection timeout.

### Error message
```
ERR_CONNECTION_TIMED_OUT
15.134.33.226 took too long to respond.
```

### How we detected it
Direct browser access to the n8n URL. The page never loaded.

### Why it happened
AWS EC2 Security Groups act as virtual firewalls. By default, all inbound
traffic is blocked except port 22 (SSH). Port 8000 was already open for
InvoiceTrack, but port 5678 had never been added to the inbound rules.

Critical distinction:
- Docker healthcheck runs INSIDE the container network → reported healthy
- AWS Security Group blocks EXTERNAL traffic → browser could not connect
These are completely independent — a service can be healthy internally
and unreachable externally simultaneously.

### What we changed
```
AWS Console → EC2 → Security Groups → invoicetrack-sg
→ Edit inbound rules → Add rule:
  Type: Custom TCP
  Port: 5678
  Source: 0.0.0.0/0
  Description: n8n UI
```

### What we learned
Always verify two separate things after deploying a service:
1. Is the service running? (docker ps, docker logs)
2. Is the firewall allowing traffic? (Security Group inbound rules)
Never assume a healthy container is accessible from the internet.

---

## FAILURE-004: Secure Cookie Error on HTTP

**Date:** 2026-03-22
**Severity:** High — n8n UI completely blocked
**Detected by:** Browser — n8n error page on /setup

### What broke
After opening port 5678, the browser reached n8n but displayed a hard
error page instead of the login/setup screen.

### Error message
```
Your n8n server is configured to use a secure cookie,
however you are either visiting this via an insecure URL, or using Safari.
```

### How we detected it
Direct browser access to http://15.134.33.226:5678/setup

### Why it happened
Modern versions of n8n default to setting cookies with the Secure flag.
The Secure flag instructs browsers to only transmit the cookie over HTTPS.
Since our server runs on plain HTTP without a domain or TLS certificate,
the browser refused to process the cookie — blocking the login entirely.

### What we changed
Added to docker-compose.yml environment section:
```yaml
- N8N_SECURE_COOKIE=false
```

Committed, pushed, PR merged to develop → promoted to main → CD deployed
automatically. n8n restarted with the new configuration.

### Security implications
Disabling secure cookies means session tokens travel over unencrypted HTTP.
Acceptable for a development/portfolio deployment. Not acceptable for
production with sensitive user data.

Permanent fix (planned): Nginx reverse proxy + Let's Encrypt TLS certificate.
Tracked in ADR-004 as a future improvement.

### What we learned
When deploying web applications without HTTPS, always check if the
application enforces security features that require HTTPS. Plan for
HTTPS from the beginning of a project — not as an afterthought.

## FAILURE-005: Claude Scoring Bias from Prompt Context

**Date:** 2026-03-23
**Severity:** Medium — incorrect lead scoring affecting routing decisions
**Detected by:** Manual review of execution output

### What broke
Claude scored a high-intent lead (specific problem, professional email,
urgent need) as 4/low — same score as a test submission.

### Error output
```
reasoning: "generic test name and email format suggest this is
a test submission rather than a genuine prospect"
```

### Why it happened
The original prompt included hardcoded example output inside the prompt
itself. Claude used that context to evaluate subsequent leads, mixing
previous examples with actual lead data. The prompt also lacked explicit
evaluation criteria, leaving Claude to infer what to score.

### What we changed
Rewrote the prompt with:
1. Explicit scoring criteria (specificity, legitimacy, urgency, fit)
2. "based ONLY on the data given" instruction to eliminate context bias
3. "based only on this lead" constraint on the reasoning field
4. Removed hardcoded examples from the prompt

### Verification
Same lead re-submitted after prompt update:
- Before: score 4, tier low
- After: score 8, tier high ✅

### What we learned
LLM prompts in production require explicit constraints to prevent
context bleeding. Always specify:
- What data to use (only the provided data)
- What criteria to apply (explicit evaluation rubric)
- What format to return (specific JSON structure)
Iterate prompts based on real output, not just expected behavior.
