#!/bin/bash
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/env.sh"

PACKAGE=$(ls -t helm-packages/*.tgz | head -1)

if [ -z "$PACKAGE" ]; then
  echo "No package found ❌"
  exit 1
fi

echo "Uploading $PACKAGE to Nexus..."

curl -u "$NEXUS_CREDS_USR:$NEXUS_CREDS_PSW" \
  --upload-file "$PACKAGE" \
  "$NEXUS_HELM_REPO_URL/$(basename "$PACKAGE")"

echo "Upload successful ✅"