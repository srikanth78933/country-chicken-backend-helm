#!/bin/bash
set -e

source scripts/env.sh

echo "Running Helm lint..."
helm lint "$CHART_PATH"

echo "Rendering Helm templates..."
helm template "$APP_NAME" "$CHART_PATH" > /dev/null

echo "Helm validation passed ✅"
