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

# -----------------------------
# Add / Update Helm repo
# -----------------------------
if ! helm repo list | grep -q "^$NEXUS_HELM_REPO"; then
  echo "➕ Adding Helm repo..."

  helm repo add "$NEXUS_HELM_REPO" "$NEXUS_HELM_REPO_URL" \
    --username "$NEXUS_USERNAME" \
    --password "$NEXUS_PASSWORD"
else
  echo "♻️ Repo already exists, updating credentials..."
  helm repo remove "$NEXUS_HELM_REPO" || true

  helm repo add "$NEXUS_HELM_REPO" "$NEXUS_HELM_REPO_URL" \
    --username "$NEXUS_USERNAME" \
    --password "$NEXUS_PASSWORD"
fi

echo "🔄 Updating Helm repo..."
helm repo update

# -----------------------------
# Verify repo connectivity
# -----------------------------
echo "🔍 Verifying Helm repo access..."
if ! curl -sSf "$NEXUS_HELM_REPO_URL/index.yaml" >/dev/null; then
  echo "❌ Cannot access Helm repo index.yaml"
  exit 1
fi

# -----------------------------
# Validate chart availability
# -----------------------------
echo "🔍 Checking chart availability..."
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
else
  echo "📦 Namespace $NAMESPACE already exists"
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
# Dry Run (Debug)
# -----------------------------
echo "🧪 Running Helm dry-run..."
helm upgrade --install "$APP_NAME" \
  "$NEXUS_HELM_REPO/$APP_NAME" \
  -n "$NAMESPACE" \
  $VALUES_ARGS \
  --dry-run --debug

# -----------------------------
# Actual Deployment
# -----------------------------
echo "🚀 Deploying to Kubernetes..."
helm upgrade --install "$APP_NAME" \
  "$NEXUS_HELM_REPO/$APP_NAME" \
  -n "$NAMESPACE" \
  $VALUES_ARGS \
  --wait \
  --timeout 5m

# -----------------------------
# Rollout Verification
# -----------------------------
echo "⏳ Checking rollout status..."
kubectl rollout status deployment/"$APP_NAME" -n "$NAMESPACE" --timeout=120s

# -----------------------------
# Output useful info
# -----------------------------
echo "📦 Pods:"
kubectl get pods -n "$NAMESPACE"

echo "🌐 Services:"
kubectl get svc -n "$NAMESPACE"

echo "🌍 Ingress:"
kubectl get ingress -n "$NAMESPACE"

# -----------------------------
# Helm History
# -----------------------------
echo "📜 Helm release history:"
helm history "$APP_NAME" -n "$NAMESPACE"

echo "✅ Deployment completed successfully"
