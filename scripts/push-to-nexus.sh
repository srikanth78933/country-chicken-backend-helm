#!/bin/bash
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/env.sh"

PACKAGE=$(ls -t helm-packages/*.tgz | head -1)

if [ -z "$PACKAGE" ]; then
  echo "No package found ❌"
  exit 1
fi

FILENAME=$(basename "$PACKAGE")

echo "Uploading $FILENAME to Nexus..."

curl -u "$NEXUS_CREDS_USR:$NEXUS_CREDS_PSW" \
  -X POST "$NEXUS_BASE_URL/service/rest/v1/components?repository=$NEXUS_HELM_REPO_NAME" \
  -F "helm.asset=@$PACKAGE" \
  -F "helm.asset.filename=$FILENAME"

echo "Upload successful ✅"
