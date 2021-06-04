#!/bin/bash
set -e
if [[ $# -ne 3 ]]; then
    echo "$0: Three arguments are required: name for the new container, name of volume to mount, python version (e.g. `3.6`)"
    exit 4
fi

echo Deleting any existing container with name: $1
docker container rm -f $1 2> /dev/null 1> /dev/null || true
mkdir -p ~/.ssh
mkdir -p ~/.aws
echo Creating container with name: $1
if [[ -d ~/.zsh-extra ]]; then
  docker container run -d \
    --name $1 \
    --mount type=volume,source=$2,target=/workspace \
    --mount type=bind,source=${HOME}/.ssh,target=/home/dev/.ssh \
    --mount type=bind,source=${HOME}/.aws,target=/home/dev/.aws \
    --mount type=bind,source=${HOME}/.zsh-extra,target=/home/dev/.zsh-extra,readonly \
    dev-container-image-python:$3
else

  docker container run -d \
    --name $1 \
    --mount type=volume,source=$2,target=/workspace \
    --mount type=bind,source=${HOME}/.ssh,target=/home/dev/.ssh \
    --mount type=bind,source=${HOME}/.aws,target=/home/dev/.aws \
    dev-container-image-python:$3
fi
echo Container created with name: $1

