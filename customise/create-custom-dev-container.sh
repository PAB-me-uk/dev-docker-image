#!/bin/bash
set -e

if [[ $# -ne 3 ]]; then
    echo "$0: Three arguments are required: name for the new container, name of volume to mount, and python version (e.g. `3.6`)"
    echo "This builds the image, creates volume if it does not exist, then creates and runs container removing any existing container with same name"
    exit 4
fi

PARENT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$PARENT_PATH"
mkdir -p ./home


if [[ -z "${NO_PULL}" ]]; then
  echo Getting latest image
  sudo docker pull pabuk/dev-python:$3
fi

export DOCKER_BUILDKIT=0
export COMPOSE_DOCKER_CLI_BUILD=0
sudo docker build . -t custom-dev-python:$3 --build-arg IMAGE_PYTHON_VERSION=$3

# Disable, looks like container will be created by docker run if it doesnt exist
# VOLUME_COUNT=$(sudo docker volume list -q | grep -Fxc $2) || true
# if [[ $VOLUME_COUNT -eq 0 ]]; then
#   echo Creating volume with name: $2
#   sudo docker volume create $2
#   echo Created volume with name $2
# else
#   echo Volume already exists with name: $2
# fi
# IS_PODMAN=$(which docker | grep -c podman) || true
# if [[ $VOLUME_COUNT -eq 0 ]]; then
#   sudo docker run -it --rm --privileged --pid=host alpine:edge nsenter -t 1 -m -u -n -i bin/bash -c "chown 1000:1000 /var/lib/docker/volumes/$2/_data" || true
# fi

echo Deleting any existing container with name: $1
sudo docker container rm -f $1 2> /dev/null 1> /dev/null || true
mkdir -p ~/.ssh
mkdir -p ~/.aws

echo Creating container with name: $1
sudo docker container run -d \
  --name $1 \
  --mount type=volume,source=$2,target=/workspace \
  --mount type=bind,source=${HOST_USER_HOME}/.ssh,target=/home/dev/.ssh \
  --mount type=bind,source=${HOST_USER_HOME}/.aws,target=/home/dev/.aws \
  --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
  --env HOST_USER_HOME=${HOST_USER_HOME} \
  custom-dev-python:$3
echo Container created with name: $1

