#!/bin/bash

# Load environment variables
set -a
source .env
set +a

IMAGE_NAME=alphailp
CONTAINER_NAME=alphailp_container
MODEL_CACHE_DIR=./models
DATA_DIR=./data

# --------------------------------------------------
# Remove existing container if it exists
# (using rm -f directly rather than stop+rm avoids a race where rm
# runs before the container has actually finished exiting)
# --------------------------------------------------
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Container ${CONTAINER_NAME} already exists. Removing it..."
    docker rm -f ${CONTAINER_NAME} 2>/dev/null || true
fi

# --------------------------------------------------
# GPU passthrough: enabled if DEVICE is set in .env and nvidia-smi
# is visible on the host. Unlike the nesy container, alphaILP's
# forward-chaining reasoning over visual scenes is heavy enough that
# you'll generally want the 5090 engaged rather than falling back to
# CPU — but the fallback is left in so the container still launches
# on a GPU-less machine for quick code inspection.
# --------------------------------------------------
GPU_FLAG=""
if [ -n "$DEVICE" ] && command -v nvidia-smi &> /dev/null; then
    echo "GPU detected and DEVICE=$DEVICE set — enabling GPU passthrough."
    GPU_FLAG="--gpus device=$DEVICE"
else
    echo "Running CPU-only (no DEVICE set or no GPU available) -- expect this to be slow for alphaILP."
fi

# --------------------------------------------------
# Run container
# --------------------------------------------------
docker run --rm \
  $GPU_FLAG \
  --name $CONTAINER_NAME \
  --memory=32g \
  --network host \
  -v ${MODEL_CACHE_DIR}:/aILP/models \
  -v ${DATA_DIR}:/aILP/data \
  -v ./scripts:/aILP/scripts \
  -v ./src:/aILP/src \
  --env-file .env \
  -it $IMAGE_NAME:latest