#!/bin/bash
set -e

# Simple rollback
RELEASE_NAME="country-chicken-backend"
NAMESPACE="country-chicken"
REVISION=$1

if [ -z "$REVISION" ]; then
  echo "Usage: $0 <revision>"
  helm history $RELEASE_NAME -n $NAMESPACE
  exit 1
fi

echo "Rolling back to revision $REVISION"
helm rollback $RELEASE_NAME $REVISION -n $NAMESPACE
echo "Rollback complete"