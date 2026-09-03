#!/usr/bin/env bash
# ORACLY Cloud Run deploy — REVIEW AND RUN MANUALLY. Not invoked by CI/tests.
# Never pass OPENAI_API_KEY as a CLI argument. Never echo secrets.
#
# First service create: Cloud Run requires the first revision to receive default
# traffic. This script always deploys a fully hardened revision (runtime SA,
# Secret Manager, fail-closed Auth/App Check). It never creates a weaker
# bootstrap. Later revisions may use --no-traffic + staging tag.
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-oracly-7f613}"
SERVICE="${SERVICE:-oracly-api}"
REGION="${REGION:-europe-west1}"
IMAGE="${IMAGE:-${REGION}-docker.pkg.dev/${PROJECT_ID}/oracly/oracly-api:latest}"
SECRET_NAME="${SECRET_NAME:-OPENAI_API_KEY}"
RUNTIME_SA="${RUNTIME_SA:-oracly-api-runtime@${PROJECT_ID}.iam.gserviceaccount.com}"
# For updates: isolate behind staging tag. First create always gets 100% traffic.
NO_TRAFFIC="${NO_TRAFFIC:-true}"
REVISION_TAG="${REVISION_TAG:-staging}"
FIREBASE_PROJECT_ID="${FIREBASE_PROJECT_ID:-oracly-7f613}"
FIREBASE_PROJECT_NUMBER="${FIREBASE_PROJECT_NUMBER:-1075374196330}"
FIREBASE_APP_CHECK_APP_IDS="${FIREBASE_APP_CHECK_APP_IDS:-1:1075374196330:android:200bc15b1e43a8a2ef2c13}"

fail() { echo "deploy-cloud-run FAIL: $*" >&2; exit 1; }

[[ "$PROJECT_ID" == *REPLACE* ]] && fail "PROJECT_ID still has a placeholder"
[[ "$IMAGE" == *REPLACE* ]] && fail "IMAGE still has a placeholder"
[[ -z "$FIREBASE_PROJECT_ID" ]] && fail "FIREBASE_PROJECT_ID required"
[[ "$FIREBASE_PROJECT_ID" == "oracly-7f613" ]] || fail "Unexpected Firebase project ID"
[[ "$FIREBASE_PROJECT_NUMBER" == "1075374196330" ]] || fail "Firebase project number contradicts Oracly client configuration"
[[ "$FIREBASE_APP_CHECK_APP_IDS" == "1:1075374196330:android:200bc15b1e43a8a2ef2c13" ]] || fail "Firebase App Check allowlist must contain only the verified app.oracly Android app"
[[ -n "${OPENAI_API_KEY_PLAINTEXT:-}" ]] && fail "Do not pass OPENAI_API_KEY_PLAINTEXT; use Secret Manager"
[[ -n "${OPENAI_API_KEY:-}" ]] && fail "Do not export OPENAI_API_KEY into deploy; use Secret Manager"
command -v gcloud >/dev/null || fail "gcloud CLI missing"
command -v docker >/dev/null || fail "docker missing"

if ! gcloud secrets describe "$SECRET_NAME" --project="$PROJECT_ID" >/dev/null 2>&1; then
  fail "Secret Manager secret '$SECRET_NAME' missing in $PROJECT_ID"
fi

if ! gcloud iam service-accounts describe "$RUNTIME_SA" --project="$PROJECT_ID" >/dev/null 2>&1; then
  fail "Runtime service account missing: oracly-api-runtime (do not fall back to default compute SA)"
fi

BACKEND_DIR="${BACKEND_DIR:-.}"
[[ -f "$BACKEND_DIR/Dockerfile" ]] || fail "Run from backend/ or set BACKEND_DIR"
[[ -f "$BACKEND_DIR/package-lock.json" ]] || fail "package-lock.json required for reproducible builds"

echo "Building image (no .env in context)…"
docker build -t "$IMAGE" "$BACKEND_DIR"

echo "Pushing image…"
docker push "$IMAGE"

# Commas in values (OPENAI_ALLOWED_MODELS) break --set-env-vars; use a file instead.
ENV_FILE="$(mktemp)"
cleanup() { rm -f "$ENV_FILE"; }
trap cleanup EXIT

{
  echo "NODE_ENV: production"
  echo "APP_ENV: production"
  echo "HOST: \"0.0.0.0\""
  echo "OPENAI_BASE_URL: https://api.openai.com/v1"
  echo "OPENAI_MODEL: gpt-4o"
  echo "OPENAI_ALLOWED_MODELS: \"gpt-4o,gpt-4o-mini\""
  echo "OPENAI_VISION: \"true\""
  echo "OPENAI_IMAGE_MODEL: gpt-image-2"
  echo "OPENAI_IMAGE_SIZE: 1024x1536"
  echo "OPENAI_IMAGE_QUALITY: high"
  echo "OPENAI_TIMEOUT_SECONDS: \"45\""
  echo "OPENAI_IMAGE_TIMEOUT_SECONDS: \"120\""
  echo "FIREBASE_PROJECT_ID: ${FIREBASE_PROJECT_ID}"
  echo "AI_AUTH_REQUIRED: \"true\""
  echo "AI_DEV_AUTH_BYPASS: \"false\""
  echo "AI_APP_CHECK_BYPASS: \"false\""
  if [[ -n "$FIREBASE_PROJECT_NUMBER" ]]; then
    echo "FIREBASE_PROJECT_NUMBER: \"${FIREBASE_PROJECT_NUMBER}\""
  fi
  if [[ -n "$FIREBASE_APP_CHECK_APP_IDS" ]]; then
    echo "FIREBASE_APP_CHECK_APP_IDS: \"${FIREBASE_APP_CHECK_APP_IDS}\""
  fi
} >"$ENV_FILE"

SERVICE_EXISTS=false
if gcloud run services describe "$SERVICE" \
  --project="$PROJECT_ID" \
  --region="$REGION" >/dev/null 2>&1; then
  SERVICE_EXISTS=true
fi

DEPLOY_ARGS=(
  --project="$PROJECT_ID"
  --region="$REGION"
  --image="$IMAGE"
  --platform=managed
  --allow-unauthenticated
  --service-account="$RUNTIME_SA"
  --port=8080
  --memory=1Gi
  --cpu=1
  --concurrency=20
  --min-instances=0
  --max-instances=1
  --timeout=180
  --cpu-boost
  --env-vars-file="$ENV_FILE"
  --set-secrets="OPENAI_API_KEY=${SECRET_NAME}:latest"
  --quiet
)

echo "Deploying Cloud Run (public ingress; app-level Auth/App Check required)…"

if [[ "$SERVICE_EXISTS" == "false" ]]; then
  # First revision MUST receive default traffic. Still fully hardened — never a weak bootstrap.
  echo "First create: assigning 100% default traffic to the hardened revision (Cloud Run requirement)."
  if [[ -n "$REVISION_TAG" ]]; then
    DEPLOY_ARGS+=(--tag="$REVISION_TAG")
  fi
  gcloud run deploy "$SERVICE" "${DEPLOY_ARGS[@]}"
elif [[ "$NO_TRAFFIC" == "true" ]]; then
  echo "Update: deploying with --no-traffic (tag=${REVISION_TAG:-none})."
  DEPLOY_ARGS+=(--no-traffic)
  if [[ -n "$REVISION_TAG" ]]; then
    DEPLOY_ARGS+=(--tag="$REVISION_TAG")
  fi
  gcloud run deploy "$SERVICE" "${DEPLOY_ARGS[@]}"
else
  echo "Promote: deploying with default traffic (NO_TRAFFIC=false)."
  gcloud run deploy "$SERVICE" "${DEPLOY_ARGS[@]}"
fi

echo "Deploy finished. Verify /health and /ready (runbook)."
echo "Note: a tagged revision at 0% traffic remains reachable via its tag URL."
echo "Rollback:"
echo "  gcloud run services update-traffic ${SERVICE} --to-revisions=PREVIOUS=100 --region=${REGION} --project=${PROJECT_ID}"
