#!/bin/bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/env.sh"

ENV=${1:-}

if [ -z "$ENV" ]; then
  echo "❌ Usage: $0 <env>"
  exit 1
fi

echo "🚀 Deploying $APP_NAME to $ENV environment..."

# -----------------------------
# Validate required env vars
# -----------------------------
: "${NEXUS_USERNAME:?NEXUS_USERNAME not set}"
: "${NEXUS_PASSWORD:?NEXUS_PASSWORD not set}"
: "${NEXUS_HELM_REPO:?NEXUS_HELM_REPO not set}"
: "${NEXUS_HELM_REPO_URL:?NEXUS_HELM_REPO_URL not set}"
: "${NAMESPACE:?NAMESPACE not set}"
: "${CHART_PATH:?CHART_PATH not set}"

# -----------------------------
# Add Helm repo (idempotent)
# -----------------------------
if ! helm repo list | awk '{print $1}' | grep -q "^$NEXUS_HELM_REPO$"; then
  echo "➕ Adding Helm repo..."
  helm repo add "$NEXUS_HELM_REPO" "$NEXUS_HELM_REPO_URL" \
    --username "$NEXUS_USERNAME" \
    --password "$NEXUS_PASSWORD"
else
  echo "♻️ Helm repo already exists"
fi

# -----------------------------
# Update repo
# -----------------------------
echo "🔄 Updating Helm repo..."
helm repo update

# -----------------------------
# Verify repo connectivity
# -----------------------------
echo "🔍 Verifying Nexus Helm repo..."
if ! curl -sSf -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
  "$NEXUS_HELM_REPO_URL/index.yaml" >/dev/null; then
  echo "❌ Cannot access Nexus Helm repo"
  exit 1
fi

# -----------------------------
# Validate chart availability
# -----------------------------
echo "🔍 Checking chart availability..."
if ! helm search repo "$NEXUS_HELM_REPO/$APP_NAME" -o json | grep -q "$APP_NAME"; then
  echo "❌ Chart $APP_NAME not found in repo"
  exit 1
fi

# -----------------------------
# Ensure namespace exists
# -----------------------------
if ! kubectl get ns "$NAMESPACE" >/dev/null 2>&1; then
  echo "📦 Creating namespace $NAMESPACE..."
  kubectl create ns "$NAMESPACE"
else
  echo "📦 Namespace already exists"
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
  echo "📄 Using env override: $ENV_VALUES"
  VALUES_ARGS="$VALUES_ARGS -f $ENV_VALUES"
else
  echo "⚠️ No env-specific values file, using base only"
fi

# -----------------------------
# Dry Run
# -----------------------------
echo "🧪 Helm dry-run..."
helm upgrade --install "$APP_NAME" \
  "$NEXUS_HELM_REPO/$APP_NAME" \
  -n "$NAMESPACE" \
  $VALUES_ARGS \
  --dry-run --debug

# -----------------------------
# Deploy
# -----------------------------
echo "🚀 Deploying to Kubernetes..."
helm upgrade --install "$APP_NAME" \
  "$NEXUS_HELM_REPO/$APP_NAME" \
  -n "$NAMESPACE" \
  $VALUES_ARGS \
  --wait \
  --timeout 5m

# -----------------------------
# Rollout check
# -----------------------------
echo "⏳ Waiting for rollout..."
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

echo "✅ Deployment successful"
