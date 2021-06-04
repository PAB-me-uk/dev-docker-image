#!/bin/bash
set -e
if [[ $# -ne 1 ]]; then
    echo "$0: A single argument for volume name is required."
    exit 4
fi

VOLUME_COUNT=$(docker volume list -q | grep -Fxc $1) || true
if [[ $VOLUME_COUNT -eq 0 ]]; then
  echo Creating volume with name: $1
  docker volume create $1
else
  echo Volume already exists with name: $1
fi
IS_PODMAN=$(which docker | grep -c podman) || true
if [[ $VOLUME_COUNT -eq 0 ]]; then
  docker run -it --rm --privileged --pid=host alpine:edge nsenter -t 1 -m -u -n -i bin/bash -c "chown 1000:1000 /var/lib/docker/volumes/$1/_data" || true
fi
