#!/bin/bash
set -e
if [[ $# -ne 1 ]]; then
    echo "$0: A single argument for python version number is required (e.g. `3.8`)."
    exit 4
fi

PARENT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$PARENT_PATH"
docker login
echo ---------------------------------------
. ./build-image.sh $1 $2 $3
echo ---------------------------------------
docker push ${IMAGE_NAME}
echo Image ${IMAGE_NAME} uploaded successfully
