# Langflow — Windows Installation Guide

Running Langflow on Windows requires a few extra steps compared to Linux, specifically around async event loop handling for PostgreSQL connections.

---

## Prerequisites

- Python 3.10 or 3.11 installed and on PATH
- Node.js 20+ installed
- PostgreSQL running (can be remote)
- Git installed

---

## Step 1 — Clone the Repository

```cmd
git clone https://github.com/langflow-ai/langflow.git
cd langflow
```

---

## Step 2 — Create & Activate Virtual Environment

```cmd
python -m venv venv
venv\Scripts\activate
```

> This isolates Python dependencies so your system Python doesn't conflict with Langflow's packages.

---

## Step 3 — Install Backend Dependencies

```cmd
pip install -e .
```

---

## Step 4 — Build the Frontend

```cmd
cd src/frontend
npm install
npm run build
```

---

## Step 5 — Copy Frontend Build into the Package

```cmd
rmdir /S /Q venv\Lib\site-packages\langflow\frontend
xcopy /E /I /Y build venv\Lib\site-packages\langflow\frontend
```

> This ensures the Python package serves the latest compiled frontend.

---

## Step 6 — Build Python Package (optional, for clean install)

```cmd
pip install build
python -m build
pip install dist/langflow-*.tar.gz
```

---

## Step 7 — PostgreSQL Setup

Connect to PostgreSQL and run:

```sql
CREATE DATABASE langflow;
CREATE USER langflowuser WITH PASSWORD 'YourStrongPassword';
GRANT ALL PRIVILEGES ON DATABASE langflow TO langflowuser;
```

---

## Step 8 — Windows Async Fix (Critical)

Windows uses `ProactorEventLoop` by default, which breaks psycopg async connections. You must force `WindowsSelectorEventLoopPolicy`.

Add this at the top of any entry point script:

```python
import asyncio
import sys

if sys.platform.startswith("win"):
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
```

> Without this, Langflow will fail to connect to PostgreSQL on Windows.

---

## Step 9 — Create the Wrapper Script

Create `run_langflow_windows.py` in your project root (see [`scripts/run_langflow_windows.py`](../scripts/run_langflow_windows.py)):

```python
import sys
import asyncio
import os
import runpy

# Windows async fix — must be first
if sys.platform.startswith("win"):
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

# Environment variables
os.environ["LANGFLOW_DATABASE_URL"] = "postgresql://langflowuser:YourPassword@<db-host>:5432/langflow"
os.environ["LANGFLOW_SUPERUSER"] = "admin"
os.environ["LANGFLOW_SUPERUSER_PASSWORD"] = "YourStrongPassword"
os.environ["ACCESS_TOKEN_EXPIRE_SECONDS"] = "3600"
os.environ["LANGFLOW_AUTO_LOGIN"] = "false"
os.environ["LANGFLOW_SECRET_KEY"] = "YourRandomSecretKeyHere"
os.environ["LANGFLOW_JOB_QUEUE"] = "sync"

# CLI arguments
sys.argv = ["langflow", "run", "--host", "0.0.0.0", "--port", "3000"]

# Run Langflow in-process (avoids ProactorEventLoop issues)
runpy.run_module("langflow.__main__", run_name="__main__")
```

> **Why `runpy` instead of `subprocess`?**
> Subprocess spawns a new process with a fresh event loop — reverting to ProactorEventLoop. Using `runpy.run_module` keeps everything in the same process where your policy fix is already applied.

---

## Step 10 — Run Langflow

```cmd
venv\Scripts\activate
python run_langflow_windows.py
```

Langflow will start, connect to PostgreSQL, create the superuser if needed, and serve the UI at `http://localhost:3000`.

---

## Step 11 — One-Click Batch Launcher (Optional)

Create `start_langflow.bat` (see [`scripts/start_langflow.bat`](../scripts/start_langflow.bat)):

```bat
@echo off
cd D:\your-project-folder\langflow
call venv\Scripts\activate
python run_langflow_windows.py
pause
```

Double-click the `.bat` file to start Langflow without opening CMD manually.

---

## Useful Commands

```cmd
REM Stop Langflow
Ctrl+C in the terminal window

REM Create additional superusers
venv\Scripts\activate
langflow superuser

REM Check what's running on port 3000
netstat -ano | findstr :3000
```

---

## Notes & Tips

- Always use a **fresh PostgreSQL database** when upgrading Langflow to avoid migration errors.
- Back up your PostgreSQL database after initial setup.
- `LANGFLOW_JOB_QUEUE=sync` is recommended on Windows — async job queues may behave unexpectedly.
- Set `LANGFLOW_AUTO_LOGIN=false` for any shared/team deployment.

---

**Next:** [Langfuse Installation](03-langfuse-installation.md)
