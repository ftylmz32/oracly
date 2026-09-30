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
EXPECTED_FIREBASE_APP_CHECK_APP_IDS="1:1075374196330:android:200bc15b1e43a8a2ef2c13,1:1075374196330:ios:5b526f23f001847eef2c13"
FIREBASE_APP_CHECK_APP_IDS="${FIREBASE_APP_CHECK_APP_IDS:-$EXPECTED_FIREBASE_APP_CHECK_APP_IDS}"

fail() { echo "deploy-cloud-run FAIL: $*" >&2; exit 1; }

[[ "$PROJECT_ID" == *REPLACE* ]] && fail "PROJECT_ID still has a placeholder"
[[ "$IMAGE" == *REPLACE* ]] && fail "IMAGE still has a placeholder"
[[ -z "$FIREBASE_PROJECT_ID" ]] && fail "FIREBASE_PROJECT_ID required"
[[ "$FIREBASE_PROJECT_ID" == "oracly-7f613" ]] || fail "Unexpected Firebase project ID"
[[ "$FIREBASE_PROJECT_NUMBER" == "1075374196330" ]] || fail "Firebase project number contradicts Oracly client configuration"
[[ "$FIREBASE_APP_CHECK_APP_IDS" == "$EXPECTED_FIREBASE_APP_CHECK_APP_IDS" ]] || fail "Firebase App Check allowlist must be exactly the verified app.oracly Android and iOS apps"
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

# G2B0 fix: --env-vars-file / --set-env-vars REPLACE the ENTIRE environment,
# which would silently delete reading-durability, billing/Apple IAP and
# review-access keys this script never lists (all live on the current
# 100%-traffic revision today). --update-env-vars only touches the keys
# named below and leaves every other existing key on the service exactly as
# it is — the only mechanism here that cannot regress into a destructive
# update. It also now binds every frozen model contract this script omitted
# (Coffee/Palm reading vision+writer+reasoning, Tarot Narrative V2, Yıldızname
# Narrative) and adds gpt-5.6-sol to the allowed-models list; Dream's binding
# was already present. A comma-escape delimiter (`gcloud topic escaping`) is
# required because OPENAI_ALLOWED_MODELS' own value contains commas.
ENV_UPDATES="^@^NODE_ENV=production"
ENV_UPDATES+="@APP_ENV=production"
ENV_UPDATES+="@HOST=0.0.0.0"
ENV_UPDATES+="@OPENAI_BASE_URL=https://api.openai.com/v1"
ENV_UPDATES+="@OPENAI_MODEL=gpt-4o"
ENV_UPDATES+="@OPENAI_ALLOWED_MODELS=gpt-4o,gpt-4o-mini,gpt-5.6-sol"
ENV_UPDATES+="@OPENAI_VISION=true"
ENV_UPDATES+="@OPENAI_IMAGE_MODEL=gpt-image-2"
ENV_UPDATES+="@OPENAI_IMAGE_SIZE=1024x1536"
ENV_UPDATES+="@OPENAI_IMAGE_QUALITY=high"
ENV_UPDATES+="@OPENAI_TIMEOUT_SECONDS=45"
ENV_UPDATES+="@OPENAI_IMAGE_TIMEOUT_SECONDS=120"
ENV_UPDATES+="@OPENAI_READING_VISION_MODEL=gpt-5.6-sol"
ENV_UPDATES+="@OPENAI_READING_WRITER_MODEL=gpt-5.6-sol"
ENV_UPDATES+="@OPENAI_READING_REASONING_EFFORT=low"
ENV_UPDATES+="@OPENAI_TAROT_NARRATIVE_MODEL=gpt-5.6-sol"
ENV_UPDATES+="@OPENAI_TAROT_NARRATIVE_REASONING_EFFORT=none"
ENV_UPDATES+="@OPENAI_YILDIZNAME_NARRATIVE_MODEL=gpt-5.6-sol"
ENV_UPDATES+="@OPENAI_YILDIZNAME_NARRATIVE_REASONING_EFFORT=none"
ENV_UPDATES+="@OPENAI_DREAM_MODEL=gpt-6-astra"
ENV_UPDATES+="@OPENAI_DREAM_REASONING_EFFORT=medium"
ENV_UPDATES+="@AI_AUTH_REQUIRED=true"
ENV_UPDATES+="@AI_DEV_AUTH_BYPASS=false"
ENV_UPDATES+="@AI_APP_CHECK_BYPASS=false"
ENV_UPDATES+="@FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID}"
if [[ -n "$FIREBASE_PROJECT_NUMBER" ]]; then
  ENV_UPDATES+="@FIREBASE_PROJECT_NUMBER=${FIREBASE_PROJECT_NUMBER}"
fi
if [[ -n "$FIREBASE_APP_CHECK_APP_IDS" ]]; then
  ENV_UPDATES+="@FIREBASE_APP_CHECK_APP_IDS=${FIREBASE_APP_CHECK_APP_IDS}"
fi

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
  --update-env-vars="$ENV_UPDATES"
  --update-secrets="OPENAI_API_KEY=${SECRET_NAME}:latest"
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
