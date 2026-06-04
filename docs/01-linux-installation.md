# Langflow — Linux Installation Guide

Tested on **Ubuntu 22.04 LTS**. Two methods are covered: the quick `uv` method and the full source/venv method.

---

## Method 1: Quick Install (Recommended for most users)

Uses `uv` — a fast Python package manager.

### Step 1 — System Update & Prerequisites

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install python3.10-venv git curl -y
```

### Step 2 — Create Project Directory & Virtual Environment

```bash
mkdir ~/langflow
cd ~/langflow
uv venv venv --clear
source venv/bin/activate
```

### Step 3 — Install Langflow

```bash
uv pip install langflow -U
```

### Step 4 — Set Environment Variables

```bash
export LANGFLOW_SUPERUSER=admin
export LANGFLOW_SUPERUSER_PASSWORD=YourStrongPassword
export LANGFLOW_AUTO_LOGIN=false
export LANGFLOW_DATABASE_URL="postgresql://langflowuser:password@<db-host>:5432/langflow"
export ACCESS_TOKEN_EXPIRE_SECONDS=3600
export LANGFLOW_SECRET_KEY="YourRandomSecretKey"
```

> Copy `configs/langflow.env.example` and fill in your values. Source it with `source .env`.

### Step 5 — Run Langflow

**Foreground (for testing):**
```bash
uv run langflow run --host 0.0.0.0 --port 7860
```

**Background (for production):**
```bash
nohup uv run langflow run --host 0.0.0.0 --port 7860 > langflow.log 2>&1 &
```

Access at: `http://<server-ip>:7860`

---

## Method 2: Full Source Build (for custom/modified deployments)

Use this when you need to modify Langflow source code or frontend.

### Step 1 — Install All Prerequisites

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install git curl ufw python3-pip python3-venv build-essential npm -y

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
node -v && npm -v
```

### Step 2 — Firewall Configuration

```bash
sudo ufw allow 22    # SSH
sudo ufw allow 80    # HTTP
sudo ufw allow 443   # HTTPS
sudo ufw allow 7860  # Langflow (or your chosen port)
sudo ufw enable
sudo ufw status verbose
```

### Step 3 — Clone Repository

```bash
cd ~
git clone https://github.com/langflow-ai/langflow.git
cd langflow
```

### Step 4 — Python Virtual Environment

```bash
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
```

### Step 5 — Install Backend

```bash
pip install -e .
```

### Step 6 — Set Up PostgreSQL Database

Create the database and user in PostgreSQL:

```sql
CREATE DATABASE langflow;
CREATE USER langflowuser WITH PASSWORD 'YourPassword';
GRANT ALL PRIVILEGES ON DATABASE langflow TO langflowuser;
```

### Step 7 — Set Environment Variables & Run Migrations

```bash
export LANGFLOW_DATABASE_URL="postgresql://langflowuser:YourPassword@<db-host>:5432/langflow"
export LANGFLOW_SUPERUSER="admin"
export LANGFLOW_SUPERUSER_PASSWORD="YourStrongPassword"
export ACCESS_TOKEN_EXPIRE_SECONDS=3600
export LANGFLOW_AUTO_LOGIN=false
export LANGFLOW_SECRET_KEY="YourRandomSecretKey"

# Apply DB migrations
alembic -c src/backend/base/langflow/alembic.ini upgrade head
```

### Step 8 — Build Frontend

```bash
cd src/frontend
npm install
export NODE_OPTIONS="--max-old-space-size=4096"
npm run build
```

**If you get "Blocked request" errors**, edit `vite.config.mts` and add your domain:

```js
server: {
  preview: {
    allowedHosts: ['your-domain.com'],
  },
}
```

### Step 9 — Start Backend

```bash
cd ~/langflow
source venv/bin/activate

# In background
nohup uvicorn base.langflow.main:create_app --factory --host 0.0.0.0 --port 8000 > backend.log 2>&1 &
```

### Step 10 — Start Frontend

```bash
cd src/frontend
nohup npx vite preview --host 0.0.0.0 --port 3000 > frontend.log 2>&1 &
```

- Backend: `http://<server-ip>:8000`
- Frontend: `http://<server-ip>:3000`

---

## Useful Commands

```bash
# Check if running
lsof -i :7860
lsof -i :8000
ss -tulnp | grep 3000

# View logs
tail -f langflow.log
tail -f backend.log

# Stop Langflow
pkill -f "langflow"
pkill -f "uvicorn.*8000"
pkill -f "vite"

# Create additional superusers
source venv/bin/activate
langflow superuser
```

---

## Troubleshooting

**Port already in use:**
```bash
lsof -i :7860
kill -9 <PID>
```

**DB migration error:**
- Always use a fresh database when upgrading Langflow versions to avoid migration conflicts.

**Dependency conflicts:**
```bash
pip uninstall -y json-repair pydantic cryptography setuptools wrapt
pip install \
  "json-repair==0.30.3" \
  "pydantic==2.10.1" \
  "cryptography>=42.0.5,<44.0.0" \
  "setuptools>=78.1.0,<79.0.0" \
  "wrapt>=1.14,<2.0"
pip check
```

---

**Next:** [Windows Installation](02-windows-installation.md) | [Langfuse Setup](03-langfuse-installation.md)
