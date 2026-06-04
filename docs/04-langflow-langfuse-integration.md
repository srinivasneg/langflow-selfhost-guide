# Langflow ↔ Langfuse Integration — End-to-End Guide

This is a production-tested runbook for integrating Langflow with Langfuse for full LLM trace observability. It includes setup steps, all issues encountered, and exact fixes.

---

## Environment Reference

| Component | Value |
|-----------|-------|
| Langflow VM | e.g. `192.168.1.10` |
| Langfuse API (langfuse-app) | `http://<langfuse-vm>:3001` |
| Langfuse UI (langfuse-web) | `http://<langfuse-vm>:3000` |
| PostgreSQL | External DB host |
| Langflow version | 1.5.0.post2+ |
| Langfuse server | Docker image v3.x |
| langfuse pip | 2.53.9 (initial) → 3.4.0 (upgraded) |

---

## Step 1 — Verify Langfuse Is Running

From the Langflow VM, confirm you can reach the Langfuse API:

```bash
curl http://<langfuse-vm-ip>:3001/api/public/health
# Expected: {"status":"OK","version":"3.x.x"}
```

If you get **connection refused**, check:
- Docker port binding is `0.0.0.0:3001` not `127.0.0.1:3001`
- The `langfuse-app` container is running: `docker ps`

---

## Step 2 — Get API Keys from Langfuse

1. Log into Langfuse UI (`http://<langfuse-vm>:3000`)
2. Create or open a Project
3. Settings → API Keys → copy **Public Key** and **Secret Key**

---

## Step 3 — Configure Langflow Environment Variables

On the Langflow VM, export these before starting Langflow:

```bash
# Langflow core settings
export LANGFLOW_DATABASE_URL="postgresql://langflowuser:password@<db-host>:5432/langflow"
export LANGFLOW_SUPERUSER="admin"
export LANGFLOW_SUPERUSER_PASSWORD="YourStrongPassword"
export ACCESS_TOKEN_EXPIRE_SECONDS=3600
export LANGFLOW_AUTO_LOGIN=false
export LANGFLOW_SECRET_KEY="YourRandomSecretKey"
export LANGFLOW_JOB_QUEUE=sync

# Langfuse integration
export LANGFUSE_HOST="http://<langfuse-vm-ip>:3001"
export LANGFUSE_PUBLIC_KEY="pk-lf-your-public-key"
export LANGFUSE_SECRET_KEY="sk-lf-your-secret-key"
```

> For permanent settings, add these to `~/.bashrc` or `~/.profile`.

---

## Step 4 — Start Langflow Backend

```bash
source venv/bin/activate

# Stop any running instance
pkill -f "uvicorn base.langflow.main" || true

# Start fresh
nohup uvicorn base.langflow.main:create_app --factory --host 0.0.0.0 --port 8000 > backend.log 2>&1 &

# Monitor startup
tail -f backend.log
```

---

## Step 5 — Enable Tracing in Code (Custom Deployments)

If you're running a modified Langflow, create `langflow/src/backend/base/langflow/tracing.py`:

```python
import os
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.sdk.resources import Resource
from opentelemetry.trace import set_tracer_provider

try:
    from langfuse._client.span_processor import LangfuseSpanProcessor
except Exception:
    LangfuseSpanProcessor = None


def init_tracing():
    public_key = os.getenv("LANGFUSE_PUBLIC_KEY")
    secret_key = os.getenv("LANGFUSE_SECRET_KEY")
    host = os.getenv("LANGFUSE_HOST")

    if not (public_key and secret_key and host):
        return

    provider = TracerProvider(resource=Resource.create({}))

    if LangfuseSpanProcessor is not None:
        processor = LangfuseSpanProcessor(
            public_key=public_key,
            secret_key=secret_key,
            host=host,
            timeout=5,
            flush_at=500,
            flush_interval=2.0,
        )
        provider.add_span_processor(processor)

    set_tracer_provider(provider)
```

Then call it early in `main.py`:

```python
# In get_lifespan() startup section
import langflow.tracing
langflow.tracing.init_tracing()
```

---

## Step 6 — Verify Traces Are Flowing

1. Open Langflow UI and run any flow (chat, agent, LLM chain)
2. Go to Langfuse UI → **Traces**
3. You should see trace entries with request/response data

**Check MinIO has objects (trace events stored):**
```bash
mc ls local/langfuse --recursive
# Should show objects under events/... prefix
```

**Check Langfuse worker logs for errors:**
```bash
docker logs -f langfuse-langfuse-worker-1
```

**Check Langflow backend logs:**
```bash
tail -f backend.log
# Should not show S3/MinIO upload failures
```

---

## Troubleshooting

### `ModuleNotFoundError: No module named 'langflow.tracing'`

The `tracing.py` file is missing. Create it as shown in Step 5.

### `NoSuchBucket` errors in Langfuse logs

The MinIO bucket doesn't exist or has the wrong name. Fix:

```bash
mc alias set local http://127.0.0.1:9090 minio miniosecret
mc mb local/langfuse
mc rm -r --force local/events   # if wrongly created
```

### Langfuse version conflicts in Langflow venv

When upgrading the `langfuse` pip package, you may see pin conflict warnings:

```bash
pip show langfuse    # check current version
pip install langfuse==3.4.0   # upgrade
```

> Note: Langflow communicates with the Langfuse server via HTTP API — the pip client version is not strictly enforced. Upgrade carefully and test.

### Traces not appearing in Langfuse UI

- Confirm `LANGFUSE_HOST` points to the **API backend** (`port 3001`), not the web UI (`port 3000`).
- Restart Langflow after updating env vars: `pkill -f uvicorn && nohup uvicorn ...`
- Check backend.log for export timeout errors — increase `timeout` in `LangfuseSpanProcessor`.

---

## Appendix — Quick Reference Commands

```bash
# Docker
docker ps
docker logs -f <container-name>
docker compose up -d
docker compose restart langfuse-app langfuse-worker
docker compose down

# MinIO client
mc alias set local http://127.0.0.1:9090 minio miniosecret
mc ls local
mc mb local/langfuse
mc ls local/langfuse --recursive

# Langflow backend
source venv/bin/activate
pkill -f "uvicorn base.langflow.main"
nohup uvicorn base.langflow.main:create_app --factory --host 0.0.0.0 --port 8000 > backend.log 2>&1 &

# Health checks
curl http://<langfuse-vm>:3001/api/public/health

# Port check
lsof -i:8000
```

---

**Next:** [Custom Templates](05-custom-templates.md)
