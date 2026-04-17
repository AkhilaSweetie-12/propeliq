#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="akhila-gcp-123-493309"
REGION="us-central1"
REPO_NAME="app-images"
SERVICE_NAME="app-service-dev"
ALLOW_UNAUTHENTICATED="true"

if [[ $# -ge 1 ]]; then
  SERVICE_NAME="$1"
fi

if [[ $# -ge 2 ]]; then
  ALLOW_UNAUTHENTICATED="$2"
fi

if [[ "$ALLOW_UNAUTHENTICATED" != "true" && "$ALLOW_UNAUTHENTICATED" != "false" ]]; then
  echo "Second argument must be true or false."
  echo "Usage: bash scripts/deploy-cloudrun-basic.sh [service-name] [true|false]"
  exit 1
fi

IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${SERVICE_NAME}:$(date +%Y%m%d-%H%M%S)"

echo "Using project: ${PROJECT_ID}"
echo "Using region: ${REGION}"
echo "Deploying service: ${SERVICE_NAME}"

gcloud config set project "$PROJECT_ID" >/dev/null

gcloud services enable run.googleapis.com artifactregistry.googleapis.com >/dev/null

if ! gcloud artifacts repositories describe "$REPO_NAME" --location "$REGION" >/dev/null 2>&1; then
  gcloud artifacts repositories create "$REPO_NAME" \
    --repository-format=docker \
    --location="$REGION" \
    --description="Container images for PropelIQ apps"
fi

gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet

docker build -t "$IMAGE" .
docker push "$IMAGE"

if [[ "$ALLOW_UNAUTHENTICATED" == "true" ]]; then
  AUTH_FLAG="--allow-unauthenticated"
else
  AUTH_FLAG="--no-allow-unauthenticated"
fi

gcloud run deploy "$SERVICE_NAME" \
  --image "$IMAGE" \
  --region "$REGION" \
  --project "$PROJECT_ID" \
  --platform managed \
  $AUTH_FLAG

SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" \
  --region "$REGION" \
  --project "$PROJECT_ID" \
  --format='value(status.url)')

echo "Deployment completed."
echo "Service URL: ${SERVICE_URL}"
echo "Health URL: ${SERVICE_URL}/health"
