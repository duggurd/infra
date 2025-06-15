
# Exit on any error
$ErrorActionPreference = "Stop"

# Configuration
$IMAGE_NAME = "hyperjob"
$TAG = "latest"
$REGISTRY = "homelab.kiko-ghoul.ts.net:30500"
$FULL_IMAGE_NAME = "${REGISTRY}/${IMAGE_NAME}:${TAG}"

Write-Host "Building Docker image: ${FULL_IMAGE_NAME}"

# Build the Docker image
docker build -t "${FULL_IMAGE_NAME}" -f docker/Dockerfile .

Write-Host "Pushing image to local registry: ${REGISTRY}"

# Push to local registry
docker push "${FULL_IMAGE_NAME}"

Write-Host "Successfully built and pushed ${FULL_IMAGE_NAME}"
