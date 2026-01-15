#!/bin/bash
set -e

# Simple validation
source scripts/env.sh

echo "Validating Helm chart..."
helm lint $CHART_PATH

echo "Dry-run template..."
helm template $APP_NAME $CHART_PATH --dry-run

echo "Validation passed!"