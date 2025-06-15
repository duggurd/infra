#!/bin/bash

# Exit on any error
set -e

# Configuration
IMAGE_NAME="hyperjob"
TAG="latest"
REGISTRY="100.100.132.104:30500"
FULL_IMAGE_NAME="${REGISTRY}/${IMAGE_NAME}:${TAG}"

echo "Building Docker image: ${FULL_IMAGE_NAME}"

# Build the Docker image
docker build -t "${FULL_IMAGE_NAME}" .

echo "Pushing image to local registry: ${REGISTRY}"

# Push to local registry
docker push "${FULL_IMAGE_NAME}"

echo "Successfully built and pushed ${FULL_IMAGE_NAME}"
