#!/bin/bash
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/env.sh"

RELEASE_NAME="$APP_NAME"
REVISION=$1

if [ -z "$REVISION" ]; then
  echo "Usage: $0 <revision>"
  helm history "$RELEASE_NAME" -n "$NAMESPACE"
  exit 1
fi

echo "Rolling back to revision $REVISION..."

helm rollback "$RELEASE_NAME" "$REVISION" -n "$NAMESPACE"

echo "Rollback complete ✅"

kubectl rollout status deployment/"$RELEASE_NAME" -n "$NAMESPACE"