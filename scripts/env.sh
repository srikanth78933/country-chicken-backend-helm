#!/bin/bash

# App details
APP_NAME="country-chicken-backend"
CHART_PATH="charts/$APP_NAME"
NAMESPACE="country-chicken"

# Nexus Helm repo (for Helm CLI)
NEXUS_HELM_REPO="nexus-helm"
NEXUS_HELM_REPO_URL="${NEXUS_HELM_REPO_URL:-http://51.21.169.25:8081/repository/helm-releases/}"

# 🔥 NEW (Required for proper upload via API)
NEXUS_BASE_URL="http://54.87.4.226:8081"
NEXUS_HELM_REPO_NAME="helm-releases"
