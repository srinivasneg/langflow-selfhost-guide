# Langfuse — Installation & Configuration Guide

Langfuse provides **observability, tracing, and monitoring** for LLM workflows. This guide covers installing Langfuse via Docker Compose on Ubuntu 22.04.

---

## Architecture Overview

```
Langflow VM  ──────────────────►  Langfuse VM
(traces via HTTP)                  ├── langfuse-app   (API backend, port 3001)
                                   ├── langfuse-web   (frontend UI, port 3000)
                                   ├── langfuse-worker
                                   ├── PostgreSQL     (metadata)
                                   ├── ClickHouse     (metrics)
                                   ├── MinIO          (event object storage)
                                   └── Redis          (queue)
```

---

## Step 1 — System Update

```bash
sudo apt update
```

---

## Step 2 — Install Prerequisites

```bash
sudo apt install ca-certificates curl gnupg lsb-release -y
```

---

## Step 3 — Add Docker's Official GPG Key

```bash
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
```

---

## Step 4 — Set Up Docker Repository

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

---

## Step 5 — Install Docker Engine & Compose

```bash
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
```

---

## Step 6 — Verify Installation

```bash
docker --version
docker compose version
```

---

## Step 7 — Clone Langfuse Repository

```bash
git clone https://github.com/langfuse/langfuse.git
cd langfuse
```

---

## Step 8 — Configure docker-compose.yml

See the full config in [`configs/docker-compose.langfuse.yml`](../configs/docker-compose.langfuse.yml).

Key environment variables to set:

```yaml
DATABASE_URL: postgresql://langfuse_db_user:password@<db-host>:5432/langfuse_db
NEXTAUTH_URL: https://your-domain.com
NEXTAUTH_SECRET: your-random-secret
ENCRYPTION_KEY: your-random-hex-key   # generate: openssl rand -hex 32
SALT: yoursalt
```

### Critical: Port Binding for Cross-VM Access

Ensure ports are bound to `0.0.0.0` (not `127.0.0.1`):

```yaml
# ✅ Correct — accessible from other VMs
ports:
  - "3001:3000"

# ❌ Wrong — only accessible locally
ports:
  - "127.0.0.1:3001:3000"
```

---

## Step 9 — Start Langfuse

```bash
docker compose up -d
```

Check containers are running:

```bash
docker ps
```

Expected containers: `langfuse-web`, `langfuse-worker`, `langfuse-app`, `clickhouse`, `minio`, `redis`.

---

## Step 10 — Access Langfuse

```
http://localhost:3000
# or
https://your-domain.com
```

Register the first user on the login screen — this becomes the admin account.

---

## Step 11 — MinIO Bucket Setup (Required)

Langfuse requires a bucket named `langfuse` in MinIO. It writes event data as objects under the `events/` prefix inside this bucket.

> ⚠️ A common mistake is creating a bucket named `events` — this will cause `NoSuchBucket` errors.

Run the setup script:

```bash
bash scripts/minio_setup.sh
```

Or manually:

```bash
# Install MinIO client
wget https://dl.min.io/client/mc/release/linux-amd64/mc -O /usr/local/bin/mc
chmod +x /usr/local/bin/mc

# Point mc at your MinIO instance (port 9090 is the host-mapped port)
mc alias set local http://127.0.0.1:9090 minio miniosecret

# List existing buckets
mc ls local

# Create the required bucket
mc mb local/langfuse

# Remove any incorrectly named buckets
mc rm -r --force local/events   # only if it exists

# Verify
mc ls local
```

---

## Step 12 — Verify Health Endpoint

```bash
curl http://<langfuse-vm-ip>:3001/api/public/health
# Expected: {"status":"OK","version":"3.x.x"}
```

---

## Step 13 — Get API Keys for Langflow Integration

1. Log into Langfuse dashboard
2. Create or open a **Project**
3. Go to **Settings** → **API Keys**
4. Copy the **Public Key** (`pk-lf-...`) and **Secret Key** (`sk-lf-...`)

---

## Useful Commands

```bash
# View logs
docker logs -f langfuse-langfuse-app-1
docker logs -f langfuse-langfuse-worker-1

# Restart specific services
docker compose restart langfuse-app langfuse-worker

# Stop everything
docker compose down

# MinIO — list bucket contents
mc ls local/langfuse --recursive
```

---

## Troubleshooting

### `NoSuchBucket` errors in Langfuse worker logs

```
NoSuchBucket: The specified bucket does not exist
Failed to upload events to blob storage, aborting event processing
```

**Fix:** Create the `langfuse` bucket in MinIO (see Step 11).

### Connection refused when curling health endpoint

- Check that Docker port binding uses `0.0.0.0` not `127.0.0.1` (see Step 8).
- Restart containers: `docker compose up -d`

### `langfuse-app` container missing

If the API backend isn't running, add the `langfuse-app` service to your `docker-compose.yml`:

```yaml
langfuse-app:
  image: docker.io/langfuse/langfuse:3
  ports:
    - "3001:3000"
  environment:
    <<: *langfuse-worker-env
    NEXTAUTH_SECRET: mysecret
```

---

**Next:** [Langflow ↔ Langfuse Integration](04-langflow-langfuse-integration.md)
