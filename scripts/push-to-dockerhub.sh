#!/bin/bash
set -e

# Usage: ./scripts/push-to-dockerhub.sh <username> [image_name] [tag]
# Example: ./scripts/push-to-dockerhub.sh myuser openclaw dokploy

USERNAME=$1
IMAGE_NAME=${2:-openclaw}
TAG=${3:-latest}

if [ -z "$USERNAME" ]; then
  echo "Error: Docker Hub username is required."
  echo "Usage: $0 <username> [image_name] [tag]"
  exit 1
fi

FULL_IMAGE_NAME="$USERNAME/$IMAGE_NAME:$TAG"

echo "🐳 Preparing to build and push $FULL_IMAGE_NAME for linux/amd64 and linux/arm64..."

# Ensure Docker Buildx is available and ready
if ! docker buildx inspect openclaw-multiarch > /dev/null 2>&1; then
  echo "🛠️  Creating new buildx builder 'openclaw-multiarch'..."
  docker buildx create --name openclaw-multiarch --use
  docker buildx inspect --bootstrap
else
  echo "✅ Using existing buildx builder 'openclaw-multiarch'."
  docker buildx use openclaw-multiarch
fi

# Build and push
echo "🚀 Building and pushing..."
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -f Dockerfile.dokploy \
  -t "$FULL_IMAGE_NAME" \
  --push \
  .

echo "🎉 Done! Image pushed to $FULL_IMAGE_NAME"
