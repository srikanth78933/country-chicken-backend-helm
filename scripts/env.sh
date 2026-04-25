#!/bin/bash

# App details
APP_NAME="country-chicken-backend"
CHART_PATH="charts/$APP_NAME"
NAMESPACE="country-chicken"

# Nexus Helm repo
NEXUS_HELM_REPO="nexus-helm"
NEXUS_HELM_REPO_URL="${NEXUS_HELM_REPO_URL:-http://51.21.169.25:8081/repository/helm-releases/}"