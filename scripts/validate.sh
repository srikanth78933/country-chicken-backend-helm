#!/bin/bash
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/env.sh"

echo "Running Helm lint..."
helm lint "$CHART_PATH"

echo "Rendering Helm templates..."
helm template "$APP_NAME" "$CHART_PATH" > /dev/null

echo "Helm validation passed ✅"