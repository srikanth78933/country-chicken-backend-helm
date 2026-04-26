#!/bin/bash
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/env.sh"

ENV=$1

if [ -z "$ENV" ]; then
  echo "Usage: $0 <env>"
  exit 1
fi

echo "Deploying to $ENV environment..."

# Ensure repo exists
if ! helm repo list | grep -q "$NEXUS_HELM_REPO"; then
  echo "Adding Helm repo..."
  helm repo add "$NEXUS_HELM_REPO" "$NEXUS_HELM_REPO_URL"
fi

echo "Updating Helm repo..."
helm repo update

# Verify chart exists before deploy (NEW - very useful)
echo "Checking chart availability..."
helm search repo "$NEXUS_HELM_REPO/$APP_NAME" || {
  echo "Chart not found in repo ❌"
  exit 1
}

# Dry run
echo "Running Helm dry-run..."
helm upgrade --install "$APP_NAME" \
  "$NEXUS_HELM_REPO/$APP_NAME" \
  -n "$NAMESPACE" \
  --create-namespace \
  -f "$CHART_PATH/values-$ENV.yaml" \
  --dry-run

# Actual deployment
echo "Deploying..."
helm upgrade --install "$APP_NAME" \
  "$NEXUS_HELM_REPO/$APP_NAME" \
  -n "$NAMESPACE" \
  --create-namespace \
  -f "$CHART_PATH/values-$ENV.yaml" \
  --wait

# Verify rollout
echo "Checking rollout..."
kubectl rollout status deployment/"$APP_NAME" -n "$NAMESPACE"

# Output info
echo "Pods:"
kubectl get pods -n "$NAMESPACE"

echo "Ingress:"
kubectl get ingress -n "$NAMESPACE"

echo "Deployment completed ✅"
