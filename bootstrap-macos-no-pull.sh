arch=$(uname -m)
if [[ "${arch}" == "arm64" || "${arch}" == "aarch64" ]]; then
  image=papasfritas/dev-python-arm:3.9 # arm64
else
  image=pabuk/dev-python:3.9 # intel/amd64
fi
docker run --rm -it --env HOST_USER_HOME=${HOME} --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock ${image} /bin/zsh -c "NO_PULL=1 /home/dev/.local/bin/create-dev-container $1 $2 $3"
