#!/bin/bash
set -e

# Simple package script
source scripts/env.sh

# Lint
helm lint $CHART_PATH

# Package
helm package $CHART_PATH --destination helm-packages/