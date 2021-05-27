set -e
if [[ $# -ne 3 ]]; then
    echo "$0: Three arguments are required: name for the new container, name of volume to mount, python version (e.g. `3.6`)"
    exit 4
fi

echo Deleting existing container with name: $1
echo Ignore any "No such container message" below:
docker container rm -f $1 || true
docker container run -d \
  --name $1 \
  --mount type=volume,source=$2,target=/home/dev/projects \
  --mount type=bind,source=${HOME}/.ssh,target=/home/dev/.ssh,readonly \
  --mount type=bind,source=${HOME}/.aws,target=/home/dev/.aws \
  --mount type=bind,source=${HOME}/.pab,target=/home/dev/.pab,readonly \
  dev-container-image-python:$3
