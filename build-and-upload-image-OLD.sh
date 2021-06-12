#!/bin/bash
set -e
if [[ $# -ne 1 ]]; then
    echo "$0: A single argument for python version number is required (e.g. `3.8`)."
    exit 4
fi

PARENT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$PARENT_PATH"

IMAGE_PYTHON_VERSION=$1
TEMP_IMAGE=temp-image-python:${IMAGE_PYTHON_VERSION}
FINAL_IMAGE=pabuk/dev-python:${IMAGE_PYTHON_VERSION}
TEMP_CONTAINER_NAME=baui-temp
TEMP_VOLUME_NAME=baui-temp-volume

docker login
echo ---------------------------------------
echo Building image with python version: ${IMAGE_PYTHON_VERSION}
export DOCKER_BUILDKIT=0
export COMPOSE_DOCKER_CLI_BUILD=0
docker build . -t ${TEMP_IMAGE} --build-arg IMAGE_PYTHON_VERSION=${IMAGE_PYTHON_VERSION}
echo ---------------------------------------
docker container rm -f ${TEMP_CONTAINER_NAME} 2> /dev/null 1> /dev/null || true
docker container run -d --name ${TEMP_CONTAINER_NAME} ${TEMP_IMAGE}
echo ---------------------------------------
docker commit -m="Release" ${TEMP_CONTAINER_NAME} ${FINAL_IMAGE}
echo ---------------------------------------
docker container rm -f ${TEMP_CONTAINER_NAME} 2> /dev/null 1> /dev/null || true
echo ---------------------------------------
docker volume rm -f ${TEMP_VOLUME_NAME} 2> /dev/null 1> /dev/null || true
echo Running check-container start
docker container run --rm -it --mount type=volume,source=,target=/workspace ${TEMP_IMAGE} bin/zsh -c "source ~/.zshrc && check-container"
echo Running check-container end
docker volume rm -f ${TEMP_VOLUME_NAME} 2> /dev/null 1> /dev/null || true
echo ---------------------------------------
if [[ -z "${NO_PUSH}" ]]; then
  docker push ${FINAL_IMAGE}
fi
