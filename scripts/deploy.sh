#!/bin/bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/env.sh"

ENV=${1:-}

if [ -z "$ENV" ]; then
  echo "Usage: $0 <env>"
  exit 1
fi

echo "🚀 Deploying $APP_NAME to $ENV environment..."

# -----------------------------
# Add Helm repo (with SSL bypass)
# -----------------------------
if ! helm repo list | grep -q "^$NEXUS_HELM_REPO"; then
  echo "➕ Adding Helm repo..."
  helm repo add "$NEXUS_HELM_REPO" "$NEXUS_HELM_REPO_URL" --insecure-skip-tls-verify
fi

echo "🔄 Updating Helm repo..."
helm repo update --insecure-skip-tls-verify

echo "📚 Helm repos:"
helm repo list

# -----------------------------
# Validate chart availability
# -----------------------------
echo "🔍 Checking chart availability..."
helm search repo "$NEXUS_HELM_REPO/$APP_NAME" || true

if ! helm search repo "$NEXUS_HELM_REPO/$APP_NAME" | grep -q "$APP_NAME"; then
  echo "❌ Chart $APP_NAME not found in repo"
  exit 1
fi

# -----------------------------
# Ensure namespace exists
# -----------------------------
if ! kubectl get ns "$NAMESPACE" >/dev/null 2>&1; then
  echo "📦 Creating namespace $NAMESPACE..."
  kubectl create ns "$NAMESPACE"
fi

# -----------------------------
# Values handling
# -----------------------------
BASE_VALUES="$CHART_PATH/values.yaml"
ENV_VALUES="$CHART_PATH/values-$ENV.yaml"

if [ ! -f "$BASE_VALUES" ]; then
  echo "❌ Base values.yaml not found"
  exit 1
fi

VALUES_ARGS="-f $BASE_VALUES"

if [ -f "$ENV_VALUES" ]; then
  echo "📄 Using environment override: $ENV_VALUES"
  VALUES_ARGS="$VALUES_ARGS -f $ENV_VALUES"
else
  echo "⚠️ No env-specific values file found, using base only"
fi

# -----------------------------
# Dry Run
# -----------------------------
echo "🧪 Running Helm dry-run..."
helm upgrade --install "$APP_NAME" \
  "$NEXUS_HELM_REPO/$APP_NAME" \
  -n "$NAMESPACE" \
  --create-namespace \
  $VALUES_ARGS \
  --dry-run --debug \
  --insecure-skip-tls-verify

# -----------------------------
# Actual Deployment
# -----------------------------
echo "🚀 Deploying to Kubernetes..."
helm upgrade --install "$APP_NAME" \
  "$NEXUS_HELM_REPO/$APP_NAME" \
  -n "$NAMESPACE" \
  --create-namespace \
  $VALUES_ARGS \
  --wait \
  --timeout 5m \
  --insecure-skip-tls-verify

# -----------------------------
# Rollout verification
# -----------------------------
echo "⏳ Checking rollout status..."
kubectl rollout status deployment/"$APP_NAME" -n "$NAMESPACE" --timeout=120s

# -----------------------------
# Output info
# -----------------------------
echo "📦 Pods:"
kubectl get pods -n "$NAMESPACE"

echo "🌐 Services:"
kubectl get svc -n "$NAMESPACE"

echo "🌍 Ingress:"
kubectl get ingress -n "$NAMESPACE"

echo "📜 Helm history:"
helm history "$APP_NAME" -n "$NAMESPACE"

echo "✅ Deployment completed successfully"
