#!/bin/bash
# start_langflow.sh — Start Langflow on Linux
# Usage: bash start_langflow.sh [venv_path] [port]

set -e

VENV_PATH="${1:-$HOME/langflow-venv}"
PORT="${2:-7860}"
LOG_FILE="langflow.log"

echo "=== Starting Langflow ==="
echo "Venv: $VENV_PATH"
echo "Port: $PORT"
echo ""

# Activate virtual environment
source "$VENV_PATH/bin/activate"

# Stop any running instance
pkill -f "langflow" 2>/dev/null || true
sleep 2

# Source .env if present
if [ -f ".env" ]; then
    echo "Loading .env file..."
    set -a
    source .env
    set +a
fi

# Start Langflow
echo "Starting Langflow on port $PORT..."
nohup langflow run --host 0.0.0.0 --port "$PORT" > "$LOG_FILE" 2>&1 &

PID=$!
echo "PID: $PID"

# Wait for startup
sleep 6

# Verify
if ss -lntp | grep -q "$PORT"; then
    echo ""
    echo "✓ Langflow is running on port $PORT"
    echo "  Access at: http://$(hostname -I | awk '{print $1}'):$PORT"
    echo "  Log file:  $LOG_FILE"
else
    echo ""
    echo "✗ Langflow failed to start. Check $LOG_FILE:"
    tail -30 "$LOG_FILE"
    exit 1
fi
