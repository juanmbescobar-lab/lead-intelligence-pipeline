# Runbook — Lead Intelligence Pipeline

Operational procedures for day-to-day management of the pipeline.

---

## Services

| Service | Port | URL | Process |
|---------|------|-----|---------|
| n8n | 5678 | http://15.134.33.226:5678 | Docker container |
| InvoiceTrack | 8000 | http://15.134.33.226:8000 | Docker container |

---

## Common Operations

### Start all services
```bash
cd ~/lead-intelligence
docker compose up -d
```

### Stop all services
```bash
cd ~/lead-intelligence
docker compose down
```

### View n8n logs
```bash
docker logs n8n --tail 50
docker logs n8n -f  # follow in real time
```

### Check service health
```bash
docker ps
# Look for: STATUS Up X minutes (healthy)
```

### Restart n8n only
```bash
docker restart n8n
```

---

## Fresh Server Deployment (Bootstrap)

> These steps are manual and only required once per new server.
> After bootstrap, all subsequent deployments are handled by CD automatically.

### Prerequisites
- EC2 instance running Ubuntu 24.04
- Docker installed
- Port 22, 5678, 8000 open in Security Group

### Step 1 — Configure swap
```bash
sudo fallocate -l 1G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
free -h  # verify swap shows 1.0Gi
```

### Step 2 — Generate GitHub deploy key
```bash
ssh-keygen -t ed25519 -C "ec2-lead-intelligence" -f ~/.ssh/github_deploy -N ""
cat ~/.ssh/github_deploy.pub
# Add this key to GitHub → repo → Settings → Deploy keys (read-only)
```

### Step 3 — Configure SSH for GitHub
```bash
cat > ~/.ssh/config << 'SSHEOF'
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/github_deploy
  IdentitiesOnly yes
SSHEOF
ssh -T git@github.com  # verify: Hi juanmbescobar-lab/...
```

### Step 4 — Clone repository
```bash
mkdir ~/lead-intelligence
cd ~/lead-intelligence
git clone git@github.com:juanmbescobar-lab/lead-intelligence-pipeline.git .
```

### Step 5 — Create .env file
```bash
cp .env.example .env
nano .env  # fill in all credentials
```

### Step 6 — Fix volume permissions (CRITICAL)
```bash
mkdir -p n8n-data
sudo chown -R 1000:1000 n8n-data/
# Without this step, n8n crashes with EACCES permission denied
```

### Step 7 — Start services
```bash
docker compose up -d
sleep 30
docker ps  # verify STATUS: Up X minutes (healthy)
```

### Step 8 — Verify external access
```bash
# Open in browser: http://<EC2_IP>:5678
# Should show n8n setup page
```

---

## Troubleshooting

### n8n is restarting in a loop
```bash
docker logs n8n --tail 20
```
- If you see EACCES permission denied → run: sudo chown -R 1000:1000 n8n-data/
- If you see out of memory → check: free -h — swap may be exhausted

### n8n is healthy but browser shows timeout
Check AWS Security Group — port 5678 must be open inbound (0.0.0.0/0).

### n8n shows secure cookie error
Add N8N_SECURE_COOKIE=false to docker-compose.yml environment section.
Commit, push, merge to main — CD will redeploy automatically.

### CD pipeline failed
1. Check GitHub Actions → Actions tab for error details
2. Check Telegram — Lead Intelligence Alerts group for notification
3. SSH to EC2 and run docker ps to check container state

---

## Cost Monitoring

### Check current AWS spend
```
AWS Console → Billing → Cost Explorer
```

### Memory usage per container
```bash
docker stats --no-stream
```

### Disk usage
```bash
df -h
du -sh ~/lead-intelligence/n8n-data/
```

### Warning signals
- Swap usage consistently > 0 → consider upgrading to t3.small
- Disk usage > 80% → rotate logs or expand EBS volume
- AWS daily spend > $0.35 → investigate unexpected resource usage
