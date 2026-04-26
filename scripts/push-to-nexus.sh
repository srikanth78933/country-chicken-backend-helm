#!/bin/bash
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/env.sh"

PACKAGE=$(ls -t helm-packages/*.tgz | head -1)

if [ -z "$PACKAGE" ]; then
  echo "No package found ❌"
  exit 1
fi

echo "Uploading $(basename $PACKAGE) to Nexus..."

RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/nexus_response.txt \
  -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
  -X POST "$NEXUS_BASE_URL/service/rest/v1/components?repository=$NEXUS_HELM_REPO_NAME" \
  -F "helm.asset=@$PACKAGE")

HTTP_CODE=$(tail -n1 <<< "$RESPONSE")

echo "HTTP Status: $HTTP_CODE"
cat /tmp/nexus_response.txt

if [ "$HTTP_CODE" != "204" ]; then
  echo "Upload failed ❌"
  exit 1
fi

echo "Upload successful ✅"
