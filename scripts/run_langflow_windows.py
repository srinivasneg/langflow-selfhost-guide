"""
run_langflow_windows.py

Windows-safe Langflow launcher.

Why this script exists:
  Windows uses ProactorEventLoop by default, which breaks psycopg async
  connections. Setting WindowsSelectorEventLoopPolicy BEFORE anything else
  is imported fixes this. Using runpy.run_module keeps everything in-process
  so the policy stays applied — subprocess would spawn a new process with
  a fresh (broken) event loop.

Usage:
  venv\\Scripts\\activate
  python run_langflow_windows.py
"""

import sys
import asyncio
import os
import runpy

# ── Windows async fix — MUST be before any other imports ──────────────────────
if sys.platform.startswith("win"):
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

# ── Environment variables ──────────────────────────────────────────────────────
# Edit these values or load from a .env file using python-dotenv
os.environ.setdefault("LANGFLOW_DATABASE_URL",
    "postgresql://langflowuser:YourPassword@<db-host>:5432/langflow")

os.environ.setdefault("LANGFLOW_SUPERUSER", "admin")
os.environ.setdefault("LANGFLOW_SUPERUSER_PASSWORD", "YourStrongPassword")
os.environ.setdefault("ACCESS_TOKEN_EXPIRE_SECONDS", "3600")
os.environ.setdefault("LANGFLOW_AUTO_LOGIN", "false")
os.environ.setdefault("LANGFLOW_SECRET_KEY", "YourRandomSecretKeyHere")
os.environ.setdefault("LANGFLOW_JOB_QUEUE", "sync")

# Optional: Langfuse tracing
# os.environ.setdefault("LANGFUSE_HOST", "http://<langfuse-vm>:3001")
# os.environ.setdefault("LANGFUSE_PUBLIC_KEY", "pk-lf-...")
# os.environ.setdefault("LANGFUSE_SECRET_KEY", "sk-lf-...")

# ── CLI arguments ─────────────────────────────────────────────────────────────
sys.argv = ["langflow", "run", "--host", "0.0.0.0", "--port", "3000"]

# ── Run Langflow in-process ───────────────────────────────────────────────────
runpy.run_module("langflow.__main__", run_name="__main__")
