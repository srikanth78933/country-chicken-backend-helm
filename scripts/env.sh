#!/bin/bash

# Simple env config
APP_NAME="country-chicken-backend"
CHART_PATH="charts/$APP_NAME"
NAMESPACE="country-chicken"

NEXUS_HELM_REPO="nexus-helm"
NEXUS_HELM_URL="${NEXUS_HELM_REPO_URL:-https://nexus.company.com/repository/helm-hosted/}"