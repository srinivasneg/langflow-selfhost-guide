# Langflow Self-Host Guide

A production-tested runbook for self-hosting **Langflow** with **PostgreSQL**, integrating **Langfuse** for observability, adding custom templates, and running on Linux or Windows — including Keycloak-based authentication.

> Written from real-world DevOps experience running Langflow in production at [MicroGrid Technologies](https://www.microgridtech.in).

---

## 📁 Repository Structure

```
langflow-selfhost-guide/
├── docs/
│   ├── 01-linux-installation.md          # Full Linux install guide (uv + venv methods)
│   ├── 02-windows-installation.md        # Windows setup with async fix + batch launcher
│   ├── 03-langfuse-installation.md       # Langfuse Docker setup guide
│   ├── 04-langflow-langfuse-integration.md  # End-to-end integration + troubleshooting
│   ├── 05-custom-templates.md            # Adding custom Starter Project templates
│   └── 06-keycloak-integration.md        # Langflow + Keycloak SSO setup
├── scripts/
│   ├── start_langflow.sh                 # Linux startup script
│   ├── start_langflow.bat                # Windows batch launcher
│   ├── run_langflow_windows.py           # Windows async-safe runner
│   ├── deploy_templates.sh               # Template deployment script (dev/test/prod)
│   └── minio_setup.sh                   # MinIO bucket setup for Langfuse
├── configs/
│   ├── docker-compose.langfuse.yml       # Langfuse full Docker Compose config
│   ├── langflow.env.example              # Langflow environment variables template
│   └── langfuse.env.example             # Langfuse environment variables template
└── templates/
    └── starter-projects/
        └── example-template.json         # Example custom Langflow template structure
```

---

## 🚀 Quick Start

Choose your setup path:

| Goal | Guide |
|------|-------|
| Install Langflow on Linux | [Linux Installation](docs/01-linux-installation.md) |
| Install Langflow on Windows | [Windows Installation](docs/02-windows-installation.md) |
| Set up Langfuse (observability) | [Langfuse Installation](docs/03-langfuse-installation.md) |
| Connect Langflow ↔ Langfuse | [Integration Guide](docs/04-langflow-langfuse-integration.md) |
| Add custom flow templates | [Custom Templates](docs/05-custom-templates.md) |
| Add Keycloak SSO login | [Keycloak Integration](docs/06-keycloak-integration.md) |

---

## 🛠️ Tech Stack

| Component | Technology |
|-----------|------------|
| Flow Builder | [Langflow](https://github.com/langflow-ai/langflow) |
| Database | PostgreSQL |
| Observability | [Langfuse](https://github.com/langfuse/langfuse) |
| Object Storage | MinIO (S3-compatible) |
| Metrics | ClickHouse |
| Queue | Redis |
| Auth (optional) | Keycloak + Azure AD B2C |
| Containers | Docker + Docker Compose |

---

## ⚡ Versions Tested

| Package | Version |
|---------|---------|
| Langflow | 1.5.x, 1.6.0 |
| Langfuse server | v3.x (Docker image) |
| langfuse pip | 2.53.9 → 3.4.0 |
| Python | 3.10, 3.11 |
| Ubuntu | 22.04 LTS |

---

## 📌 Key Things Learned in Production

- Always use a **fresh PostgreSQL database** to avoid migration conflicts on upgrades.
- On Windows, you **must** apply the `WindowsSelectorEventLoopPolicy` fix for psycopg async to work.
- Langfuse's MinIO bucket must be named `langfuse` — it writes events as a **prefix** (`events/`), not as a separate bucket.
- When upgrading `langfuse` pip package inside the Langflow venv, watch for **version pin conflicts**.
- Langflow communicates with Langfuse via **HTTP API** — the pip client version on the Langflow side is not strictly enforced.
- Docker port bindings must use `0.0.0.0:PORT` (not `127.0.0.1:PORT`) for cross-VM access.

---

## 🤝 Contributing

If you've run into issues or have improvements, feel free to open a PR or issue. All runbooks here are based on real production deployments and are maintained accordingly.

---

## 📄 License

MIT — use freely, attribution appreciated.
