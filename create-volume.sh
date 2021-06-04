#!/bin/bash
set -e
if [[ $# -ne 1 ]]; then
    echo "$0: A single argument for volume name is required."
    exit 4
fi

echo Creating volume with name: $1 \(if it does not already exist\)

docker volume create --name $1
docker run -it --rm --privileged --pid=host alpine:edge nsenter -t 1 -m -u -n -i bin/bash -c "chown 1000:1000 /var/lib/docker/volumes/$1/_data"
