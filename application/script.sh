#!/bin/bash
# Build and push Docker images
# Usage: ./script.sh [with-newrelic|without-newrelic]

set -euo pipefail

DOCKER_USER="trainer1234"

# Accepts 'with-newrelic' or 'without-newrelic' as the first argument
MODE="${1:-without-newrelic}"

if [[ "$MODE" == "with-newrelic" ]]; then
  DOCKERFILE_NAME="Dockerfile-with-NewRelic"
  TAG="withnewrelic"
else
  DOCKERFILE_NAME="Dockerfile"
  TAG="withoutnewrelic"
fi

services=(
  "dotnet"
  "react-crud-app"
  "python"
)

for service in "${services[@]}"; do
  dir="${service%%|*}"
  image="${service##*|}"

  echo "=== Building $image from $dir using $DOCKERFILE_NAME ==="
  docker build -t "$DOCKER_USER/$image:$TAG" -f "$dir/$DOCKERFILE_NAME" "$dir"

  echo "=== Pushing $image ==="
  docker push "$DOCKER_USER/$image:$TAG"
done

echo "✅ All images built and pushed successfully!"