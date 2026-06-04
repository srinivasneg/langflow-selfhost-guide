#!/bin/bash
# deploy_templates.sh — Deploy custom Langflow templates
#
# Usage:
#   bash deploy_templates.sh <venv_path> <templates_dir> [env]
#
# Examples:
#   bash deploy_templates.sh ~/langflow-venv ./templates          # dev
#   bash deploy_templates.sh ~/langflow-venv ./templates test     # test
#   bash deploy_templates.sh ~/langflow-venv ./templates prod     # production

set -e

LANGFLOW_VENV="${1:-$HOME/langflow-venv}"
TEMPLATES_DIR="${2:-.}"
ENVIRONMENT="${3:-dev}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
PORT=7860

echo "=== Langflow Template Deployment ==="
echo "Environment : $ENVIRONMENT"
echo "Venv        : $LANGFLOW_VENV"
echo "Templates   : $TEMPLATES_DIR"
echo "Timestamp   : $TIMESTAMP"
echo ""

# Activate and find starter_projects path
source "$LANGFLOW_VENV/bin/activate"

STARTER_PROJECTS="$("$LANGFLOW_VENV/bin/python3" -c \
  'import langflow, os; print(os.path.join(os.path.dirname(langflow.__file__), "initial_setup/starter_projects"))')"

echo "Starter projects dir: $STARTER_PROJECTS"

# Production: backup database first
if [ "$ENVIRONMENT" = "prod" ]; then
    LANGFLOW_DB="$(find "$LANGFLOW_VENV" -name langflow.db -type f | head -1)"
    if [ -n "$LANGFLOW_DB" ]; then
        echo "Creating database backup..."
        cp "$LANGFLOW_DB" "$LANGFLOW_DB.backup.$TIMESTAMP"
        echo "✓ Backup: $LANGFLOW_DB.backup.$TIMESTAMP"
    fi
fi

# Copy templates
echo ""
echo "Deploying templates..."
DEPLOYED=0
for template in "$TEMPLATES_DIR"/*.json; do
    if [ -f "$template" ]; then
        # Validate JSON
        if python3 -m json.tool "$template" > /dev/null 2>&1; then
            cp "$template" "$STARTER_PROJECTS/$(basename "$template")"
            echo "  ✓ $(basename "$template")"
            DEPLOYED=$((DEPLOYED + 1))
        else
            echo "  ✗ INVALID JSON: $(basename "$template") — skipped"
        fi
    fi
done

if [ "$DEPLOYED" -eq 0 ]; then
    echo "No valid templates found in $TEMPLATES_DIR"
    exit 1
fi

echo ""
echo "Restarting Langflow..."
pkill -f "langflow" 2>/dev/null || true
sleep 2

nohup langflow run --host 0.0.0.0 --port "$PORT" > langflow.log 2>&1 &
sleep 8

# Verify startup
if ss -lntp | grep -q "$PORT"; then
    echo "✓ Langflow running on port $PORT"

    # Show deployed templates
    if command -v sqlite3 &>/dev/null; then
        LANGFLOW_DB="$(find "$LANGFLOW_VENV" -name langflow.db -type f | head -1)"
        if [ -n "$LANGFLOW_DB" ]; then
            echo ""
            echo "Templates in Starter Projects:"
            sqlite3 "$LANGFLOW_DB" \
              "SELECT '  - ' || name FROM flow WHERE folder_id IN (SELECT id FROM folder WHERE name LIKE 'Starter%') ORDER BY name;" 2>/dev/null || true
        fi
    fi

    echo ""
    echo "=== Deployment successful ($DEPLOYED templates) ==="
    [ -n "${LANGFLOW_DB:-}" ] && [ "$ENVIRONMENT" = "prod" ] && \
        echo "Backup: $LANGFLOW_DB.backup.$TIMESTAMP"
else
    echo ""
    echo "✗ Langflow failed to start"

    # Production: auto-rollback
    if [ "$ENVIRONMENT" = "prod" ] && [ -n "${LANGFLOW_DB:-}" ]; then
        echo "Rolling back to backup..."
        cp "$LANGFLOW_DB.backup.$TIMESTAMP" "$LANGFLOW_DB"
        nohup langflow run --host 0.0.0.0 --port "$PORT" > langflow.log 2>&1 &
        sleep 6
        echo "✓ Rolled back"
    fi

    tail -30 langflow.log
    exit 1
fi
