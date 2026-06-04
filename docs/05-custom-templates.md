# Langflow — Custom Starter Project Templates

This guide shows how to add custom flow templates that appear in the **Starter Projects** folder in the Langflow UI. Tested and working as of January 2026.

---

## How It Works

- Templates are **JSON files** stored in `initial_setup/starter_projects/` inside the Langflow package
- Langflow loads them into the database **at server startup**
- Category grouping uses the naming pattern: `CategoryName / TemplateName`
- Templates appear in the UI under **Starter Projects** folder

---

## Prerequisites

- Langflow installed in a virtual environment
- Virtual environment activated
- Template JSON file(s) ready (exported from Langflow UI or created manually)
- SSH/terminal access to the server

---

## Step 1 — Find the Starter Projects Directory

```bash
source ~/langflow-venv/bin/activate

python3 -c "import langflow, os; print(os.path.join(os.path.dirname(langflow.__file__), 'initial_setup/starter_projects'))"
```

**Example output:**
```
/home/user/langflow-venv/lib/python3.10/site-packages/langflow/initial_setup/starter_projects
```

Save this as `STARTER_PROJECTS_DIR` — you'll use it repeatedly:

```bash
export STARTER_PROJECTS_DIR="<output-from-above>"
```

---

## Step 2 — Prepare Your Template

### Option A: Export from Langflow UI

1. Log into Langflow (`http://localhost:7860`)
2. Create or open a flow
3. Click **Export** → **Download as JSON**
4. Save the file (e.g., `my-template.json`)

### Option B: Create from Scratch

Your JSON must contain these fields:

```json
{
  "id": "unique-uuid-string",
  "name": "Healthcare / Healthcare RAG",
  "description": "Template description here",
  "data": {
    "nodes": [],
    "edges": [],
    "viewport": {}
  },
  "tags": ["healthcare", "rag"],
  "is_component": false
}
```

### Step 2a — Add Category Prefix to Name

The name format `CategoryName / TemplateName` controls grouping in the UI:

```bash
python3 <<'EOF'
import json
from pathlib import Path

template_file = Path("my-template.json")
template = json.loads(template_file.read_text())

template["name"] = "Healthcare / Healthcare RAG"
template["description"] = "Load and analyze healthcare data with RAG."
template["tags"] = ["healthcare", "rag"]

template_file.write_text(json.dumps(template, indent=2))
print(f"Updated: {template['name']}")
EOF
```

### Step 2b — Validate JSON

```bash
python3 -m json.tool my-template.json > /dev/null && echo "✓ JSON valid"
```

---

## Step 3 — Copy Template to Starter Projects

```bash
cp my-template.json "$STARTER_PROJECTS_DIR/MyTemplate.json"
ls -lh "$STARTER_PROJECTS_DIR/MyTemplate.json"
```

---

## Step 4 — Restart Langflow

Templates are only loaded at startup:

```bash
pkill -f "langflow" || true
sleep 2

source ~/langflow-venv/bin/activate
nohup langflow run --host 0.0.0.0 --port 7860 > langflow.log 2>&1 &
sleep 6

# Verify it's running
ss -lntp | grep 7860
```

---

## Step 5 — Verify in Database

```bash
LANGFLOW_DB="$(find ~/langflow-venv -name langflow.db -type f | head -1)"

sqlite3 "$LANGFLOW_DB" \
  "SELECT name FROM flow WHERE folder_id IN (SELECT id FROM folder WHERE name LIKE 'Starter%') ORDER BY name;"
```

---

## Step 6 — Verify in UI

1. Open `http://<server-ip>:7860` in browser
2. Log in if required
3. Left panel → **Starter Projects** folder
4. Look for your template name

> Hard-refresh if needed: `Ctrl+Shift+R` (Linux/Windows) or `Cmd+Shift+R` (Mac)

---

## Adding Multiple Templates

### Batch Method

```bash
python3 <<'EOF'
import json, uuid
from pathlib import Path

STARTER_PROJECTS_DIR = "<your-starter-projects-dir>"

# Read base template
base = json.loads(Path("base-template.json").read_text())

templates = {
    "Healthcare": {
        "name": "Healthcare / Healthcare RAG",
        "description": "Load and analyze healthcare data with RAG.",
        "tags": ["healthcare", "rag"]
    },
    "Finance": {
        "name": "Finance / Financial Analysis",
        "description": "Analyze financial data and generate reports.",
        "tags": ["finance", "analysis"]
    },
    "DevOps": {
        "name": "DevOps / Infrastructure Automation",
        "description": "Automate infrastructure and deployment workflows.",
        "tags": ["devops", "infrastructure"]
    }
}

for category, config in templates.items():
    template = base.copy()
    template["id"] = str(uuid.uuid4())
    template["name"] = config["name"]
    template["description"] = config["description"]
    template["tags"] = config["tags"]

    out_file = Path(STARTER_PROJECTS_DIR) / f"{category}.json"
    out_file.write_text(json.dumps(template, indent=2))
    print(f"✓ Created {category}.json")
EOF
```

---

## Deployment Scripts

Use the included scripts for consistent deployments across environments:

```bash
# Dev / Test
bash scripts/deploy_templates.sh ~/langflow-venv ./templates

# Production (includes DB backup + auto-rollback)
bash scripts/deploy_templates.sh ~/langflow-venv ./templates prod
```

See [`scripts/deploy_templates.sh`](../scripts/deploy_templates.sh) for full script.

---

## Rollback

### Remove Templates

```bash
rm -f "$STARTER_PROJECTS_DIR/Healthcare.json"
rm -f "$STARTER_PROJECTS_DIR/Finance.json"
rm -f "$STARTER_PROJECTS_DIR/DevOps.json"

pkill -f "langflow" || true
sleep 2
source ~/langflow-venv/bin/activate
nohup langflow run --host 0.0.0.0 --port 7860 > langflow.log 2>&1 &
```

### Restore from DB Backup

```bash
LANGFLOW_DB="$(find ~/langflow-venv -name langflow.db -type f | head -1)"
BACKUP="$LANGFLOW_DB.backup.YYYYMMDD_HHMMSS"

cp "$BACKUP" "$LANGFLOW_DB"

pkill -f "langflow" || true
sleep 2
nohup langflow run --host 0.0.0.0 --port 7860 > langflow.log 2>&1 &
```

---

## Troubleshooting

**Templates not appearing:**
```bash
# Check file exists
ls -lh "$STARTER_PROJECTS_DIR" | grep -E "(Healthcare|Finance|DevOps)"

# Validate JSON
python3 -m json.tool "$STARTER_PROJECTS_DIR/Healthcare.json" > /dev/null

# Check Langflow is running on port
ss -lntp | grep 7860

# Check logs
tail -100 langflow.log | grep -i "error\|exception"

# Verify in DB
sqlite3 "$LANGFLOW_DB" "SELECT name FROM flow WHERE folder_id IN (SELECT id FROM folder WHERE name LIKE 'Starter%') LIMIT 50;"
```

**Templates in DB but not in UI:**
```bash
# Clear Langflow cache
rm -rf ~/.langflow/cache 2>/dev/null || true
rm -rf ~/.config/langflow 2>/dev/null || true

# Restart and hard-refresh browser
pkill -f "langflow" || true && sleep 2
nohup langflow run --host 0.0.0.0 --port 7860 > langflow.log 2>&1 &
```

---

## Quick Reference

```bash
# Find starter projects dir
python3 -c "import langflow, os; print(os.path.join(os.path.dirname(langflow.__file__), 'initial_setup/starter_projects'))"

# Stop / Start
pkill -f "langflow" || true && sleep 2
nohup langflow run --host 0.0.0.0 --port 7860 > langflow.log 2>&1 &

# List templates in DB
LANGFLOW_DB="$(find ~/langflow-venv -name langflow.db -type f | head -1)"
sqlite3 "$LANGFLOW_DB" "SELECT name FROM flow WHERE folder_id IN (SELECT id FROM folder WHERE name LIKE 'Starter%') ORDER BY name;"
```

---

**Next:** [Keycloak Integration](06-keycloak-integration.md)
