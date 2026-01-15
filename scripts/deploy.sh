#!/bin/bash
set -e

# Simple deploy script
ENV=$1

if [ -z "$ENV" ]; then
  echo "Usage: $0 <env>"
  echo "Environments: dev, prod"
  exit 1
fi

# Source env
source scripts/env.sh

# Add repo
helm repo add $NEXUS_HELM_REPO $NEXUS_HELM_URL
helm repo update

# Deploy
helm upgrade --install $APP_NAME \
  $NEXUS_HELM_REPO/$APP_NAME \
  -n $NAMESPACE \
  --create-namespace \
  -f $CHART_PATH/values-$ENV.yaml \
  --wait