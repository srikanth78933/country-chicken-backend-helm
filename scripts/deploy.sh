#!/bin/bash
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/env.sh"

ENV=$1

if [ -z "$ENV" ]; then
  echo "Usage: $0 <env>"
  echo "Example: $0 dev | prod"
  exit 1
fi

echo "Deploying to $ENV environment..."

# Add repo only if not exists
if ! helm repo list | grep -q "$NEXUS_HELM_REPO"; then
  echo "Adding Helm repo..."
  helm repo add "$NEXUS_HELM_REPO" "$NEXUS_HELM_REPO_URL"
fi

helm repo update

# Dry run (VERY IMPORTANT)
echo "Running Helm dry-run..."
helm upgrade --install "$APP_NAME" \
  "$NEXUS_HELM_REPO/$APP_NAME" \
  -n "$NAMESPACE" \
  --create-namespace \
  -f "$CHART_PATH/values-$ENV.yaml" \
  --dry-run --debug

# Actual deployment
echo "Deploying to Kubernetes..."
helm upgrade --install "$APP_NAME" \
  "$NEXUS_HELM_REPO/$APP_NAME" \
  -n "$NAMESPACE" \
  --create-namespace \
  -f "$CHART_PATH/values-$ENV.yaml" \
  --wait

# Verify rollout
echo "Checking rollout status..."
kubectl rollout status deployment/"$APP_NAME" -n "$NAMESPACE"

# Show ingress
echo "Ingress details:"
kubectl get ingress -n "$NAMESPACE"

echo "Deployment completed successfully ✅"