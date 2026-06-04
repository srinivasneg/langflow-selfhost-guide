# Langflow — Keycloak SSO Integration

This guide covers setting up Langflow with **Keycloak** as the identity provider for Single Sign-On (SSO). Tested with a custom `keycloak_langflow_app.py` wrapper.

---

## Prerequisites

- Langflow installed in a virtual environment (see [Linux Installation](01-linux-installation.md))
- Keycloak server running and accessible
- A Keycloak realm and client configured for Langflow
- Domain/URL for the Langflow deployment

---

## Step 1 — Install Required Dependencies

```bash
source venv/bin/activate

# Keycloak + Auth
pip install python-keycloak python-dotenv uvicorn itsdangerous

# AI/ML packages (as needed)
pip install unstructured sentence_transformers groq

# Database drivers
pip install "psycopg[binary]" psycopg2-binary

# Other utilities
pip install PyPDF2 paho-mqtt fastapi
```

---

## Step 2 — Fix Dependency Compatibility (if needed)

If you see dependency conflicts after install:

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

## Step 3 — Set Up Project Directory

```bash
mkdir -p /root/collokiflow
cd /root/collokiflow

python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install langflow==1.6.0
```

---

## Step 4 — Extract the Keycloak-Enabled Project

If you have a pre-built project archive:

```bash
cd /root/collokiflow
unzip langflow-keycloak-project.zip
cd langflow-keycloak-project
```

---

## Step 5 — Configure the .env File

Create a `.env` file in the project directory:

```env
# Keycloak Configuration
KEYCLOAK_SERVER_URL=https://your-keycloak-domain.com
KEYCLOAK_REALM=your-realm-name
KEYCLOAK_CLIENT_ID=your-client-id
KEYCLOAK_CLIENT_SECRET=your-client-secret
KEYCLOAK_REDIRECT_URI=https://your-langflow-domain.com/auth/callback

# Langflow Configuration
LANGFLOW_DATABASE_URL=postgresql://langflowuser:password@<db-host>:5432/langflow
LANGFLOW_SUPERUSER=admin
LANGFLOW_SUPERUSER_PASSWORD=YourStrongPassword
LANGFLOW_AUTO_LOGIN=false
LANGFLOW_SECRET_KEY=YourRandomSecretKey
ACCESS_TOKEN_EXPIRE_SECONDS=3600
```

> Copy `configs/langflow.env.example` as a starting point.

---

## Step 6 — Validate Environment Loading

```bash
python3 - << 'EOF'
import os
from dotenv import load_dotenv

load_dotenv('/root/collokiflow/langflow-keycloak-project/.env')

print("KEYCLOAK_SERVER_URL:", os.getenv("KEYCLOAK_SERVER_URL"))
print("KEYCLOAK_CLIENT_ID:", os.getenv("KEYCLOAK_CLIENT_ID"))
print("KEYCLOAK_REALM:", os.getenv("KEYCLOAK_REALM"))
EOF
```

---

## Step 7 — Validate Langflow Initialization

```bash
python3 - << 'EOF'
from langflow.main import initialize_settings

initialize_settings()
print("Settings OK")
EOF
```

---

## Step 8 — Start the Service

**Foreground (for testing):**
```bash
python keycloak_langflow_app.py
```

**Background (for production):**
```bash
mkdir -p /var/log/collokiflow

nohup python keycloak_langflow_app.py > /var/log/collokiflow/collokiflow.log 2>&1 &
```

---

## Keycloak Setup Checklist

Before running, ensure Keycloak is configured:

- [ ] Realm created (e.g., `colloki`)
- [ ] Client created with:
  - Client ID matching `KEYCLOAK_CLIENT_ID`
  - Access Type: `confidential`
  - Valid Redirect URIs: `https://your-domain.com/auth/callback`
  - Web Origins: `https://your-domain.com`
- [ ] Client secret copied to `.env`
- [ ] User(s) created in the realm

---

## Troubleshooting

**Import errors on startup:**
```bash
# Check langflow can be imported
python3 -c "import langflow; print(langflow.__version__)"

# Check keycloak client
python3 -c "from keycloak import KeycloakOpenID; print('OK')"
```

**Auth callback failing:**
- Confirm `KEYCLOAK_REDIRECT_URI` exactly matches what's configured in Keycloak client settings
- Check Keycloak logs for redirect URI mismatch errors

**Token expiry issues:**
- Adjust `ACCESS_TOKEN_EXPIRE_SECONDS` in `.env`
- Check Keycloak session settings (SSO Session Max)

---

**Back to:** [README](../README.md)
