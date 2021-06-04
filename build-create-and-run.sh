#!/bin/bash
set -e
if [[ $# -ne 3 ]]; then
    echo "$0: Three arguments are required: name for the new container, name of volume to mount, and python version (e.g. `3.6`)"
    echo "This builds the image, creates volume if it does not exist, then creates and runs container removing any existing container with same name"
    exit 4
fi

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"

. build-image.sh $3
echo ---------------------------------------
. create-volume.sh $2
echo ---------------------------------------
. create-and-run-container.sh $1 $2 $3
