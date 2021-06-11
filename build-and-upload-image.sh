#!/bin/bash
set -e
if [[ $# -ne 1 ]]; then
    echo "$0: A single argument for python version number is required (e.g. `3.8`)."
    exit 4
fi

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"

docker login
echo ---------------------------------------
. build-image.sh $1
echo ---------------------------------------
TEMP_CONTAINER_NAME=baui-temp
TEMP_VOLUME_NAME=baui-temp-volume
docker container rm -f ${TEMP_CONTAINER_NAME} 2> /dev/null 1> /dev/null || true
docker container run -d --name ${TEMP_CONTAINER_NAME} dev-container-image-python:$1
echo ---------------------------------------
docker commit -m="Release" ${TEMP_CONTAINER_NAME} pabuk/dev-python:$1
echo ---------------------------------------
docker container rm -f ${TEMP_CONTAINER_NAME} 2> /dev/null 1> /dev/null || true
echo ---------------------------------------
docker volume rm -f ${TEMP_VOLUME_NAME} 2> /dev/null 1> /dev/null || true
echo Running check-container start
docker container run --rm -it --mount type=volume,source=,target=/workspace dev-container-image-python:$1 bin/zsh -c "source ~/.zshrc && check-container"
echo Running check-container end
docker volume rm -f ${TEMP_VOLUME_NAME} 2> /dev/null 1> /dev/null || true
echo ---------------------------------------
if [[ -z "${NO_PUSH}" ]]; then
  docker push pabuk/dev-python:$1
fi
