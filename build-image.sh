#!/bin/bash
set -e
if [[ $# -ne 1 ]]; then
    echo "$0: A single argument for python version number is required (e.g. `3.8`)."
    exit 4
fi

PARENT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$PARENT_PATH"

IMAGE_PYTHON_VERSION=$1
IMAGE_NAME=pabuk/dev-python:${IMAGE_PYTHON_VERSION}
TEMP_VOLUME_NAME=temp-volume-for-check-container-${IMAGE_PYTHON_VERSION}

echo Building image ${IMAGE_NAME} with python version: ${IMAGE_PYTHON_VERSION}
export DOCKER_BUILDKIT=0
export COMPOSE_DOCKER_CLI_BUILD=0
time docker build . -t ${IMAGE_NAME} --build-arg IMAGE_PYTHON_VERSION=${IMAGE_PYTHON_VERSION}
if [[ -z "${NO_TEST}" ]]; then
  echo ---------------------------------------
  echo Testing container
  docker container run --rm -it --mount type=volume,source=${TEMP_VOLUME_NAME},target=/workspace ${IMAGE_NAME} bin/zsh -c "source ~/.zshrc && check-container"
  docker volume rm -f ${TEMP_VOLUME_NAME} 2> /dev/null 1> /dev/null || true
  echo Image ${IMAGE_NAME} built successfully
fi
