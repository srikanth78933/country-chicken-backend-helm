#!/bin/bash
set -e

# Simple push to nexus
source scripts/env.sh

PACKAGE=$(ls -t helm-packages/*.tgz | head -1)

curl -u "$NEXUS_USER:$NEXUS_PASS" \
  --upload-file "$PACKAGE" \
  "$NEXUS_HELM_REPO_URL/$(basename "$PACKAGE")"