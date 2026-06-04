#!/bin/bash
# minio_setup.sh — Set up MinIO bucket for Langfuse
#
# Langfuse writes trace event objects under the prefix 'events/' inside
# a bucket named 'langfuse'. This is NOT a bucket called 'events'.
#
# Usage:
#   bash minio_setup.sh [minio_host] [minio_port] [root_user] [root_password]
#
# Defaults:
#   host=127.0.0.1  port=9090  user=minio  password=miniosecret

set -e

MINIO_HOST="${1:-127.0.0.1}"
MINIO_PORT="${2:-9090}"
MINIO_USER="${3:-minio}"
MINIO_PASS="${4:-miniosecret}"
BUCKET_NAME="langfuse"

echo "=== MinIO Setup for Langfuse ==="
echo "Host   : $MINIO_HOST:$MINIO_PORT"
echo "Bucket : $BUCKET_NAME"
echo ""

# Install mc if not present
if ! command -v mc &>/dev/null; then
    echo "Installing MinIO client (mc)..."
    wget -q https://dl.min.io/client/mc/release/linux-amd64/mc -O /usr/local/bin/mc
    chmod +x /usr/local/bin/mc
    echo "✓ mc installed"
fi

# Configure alias
echo "Configuring mc alias..."
mc alias set langfuse-minio "http://$MINIO_HOST:$MINIO_PORT" "$MINIO_USER" "$MINIO_PASS" --api S3v4

# List existing buckets
echo ""
echo "Existing buckets:"
mc ls langfuse-minio || true

# Remove incorrect 'events' bucket if it exists (common mistake)
if mc ls langfuse-minio/events &>/dev/null 2>&1; then
    echo ""
    echo "⚠ Found bucket named 'events' — this is incorrect. Removing..."
    mc rm -r --force langfuse-minio/events
    echo "✓ Removed 'events' bucket"
fi

# Create the correct 'langfuse' bucket if it doesn't exist
if ! mc ls langfuse-minio/$BUCKET_NAME &>/dev/null 2>&1; then
    echo ""
    echo "Creating bucket '$BUCKET_NAME'..."
    mc mb langfuse-minio/$BUCKET_NAME
    echo "✓ Created bucket '$BUCKET_NAME'"
else
    echo ""
    echo "✓ Bucket '$BUCKET_NAME' already exists"
fi

# Final verification
echo ""
echo "Current buckets:"
mc ls langfuse-minio

echo ""
echo "=== MinIO setup complete ==="
echo "Langfuse will write events to: $BUCKET_NAME/events/<trace-data>"
