#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PROJECT_ID=${FIREBASE_PROJECT_ID:-${GOOGLE_CLOUD_PROJECT:-}}

if [ -z "$PROJECT_ID" ]; then
  echo "Set FIREBASE_PROJECT_ID (or GOOGLE_CLOUD_PROJECT) before running this preflight." >&2
  exit 2
fi

cd "$ROOT_DIR/functions"
npm ci
npm run lint
npm test

cat <<EOF

Firebase Functions preflight passed for project: $PROJECT_ID

No cloud resources were changed. After reviewing APIs, quotas, App Check,
secrets, and the release checklist, the scoped deployment command is:

  firebase deploy --only functions:gomode --project $PROJECT_ID
EOF
