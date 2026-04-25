#!/bin/bash
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/env.sh"

echo "Linting chart..."
helm lint "$CHART_PATH"

echo "Packaging chart..."
mkdir -p helm-packages
helm package "$CHART_PATH" --destination helm-packages/

echo "Package created successfully ✅"