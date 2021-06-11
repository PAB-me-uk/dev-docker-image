#!/bin/bash
set -e
if [[ $# -ne 1 ]]; then
    echo "$0: A single argument for python version number is required (e.g. `3.8`)."
    exit 4
fi

echo Building image with python version: $1

export DOCKER_BUILDKIT=0
export COMPOSE_DOCKER_CLI_BUILD=0
docker build . -t dev-container-image-python:$1 --build-arg IMAGE_PYTHON_VERSION=$1
