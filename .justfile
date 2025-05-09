# Load .env file to populate all envars.
set dotenv-load

home := `echo "${HOME}"`
root_dir := justfile_directory()

image_name := "pabuk/dev-python"

# Default recipe, runs if you just type `just`.
[private]
default:
  just --list

# Edit the current .justfile
edit:
  code {{justfile()}}

# Build a single image
build-image python-version no-cache="":
  #!/usr/bin/env bash
  set -euo pipefail
  image_name_and_tag="{{image_name}}:{{python-version}}"
  temp_volume_name=temp-volume-for-check-container-{{python-version}}
  sudo docker volume rm -f ${temp_volume_name} 2> /dev/null 1> /dev/null || true

  echo Building image ${image_name_and_tag} with python version: {{python-version}}
  # export DOCKER_BUILDKIT=0
  export COMPOSE_DOCKER_CLI_BUILD=0
  if [[ -z "{{no-cache}}" ]]; then
    echo Using cache
    time sudo docker build . -t ${image_name_and_tag} --progress=plain  \
    --build-arg IMAGE_PYTHON_VERSION={{python-version}}
  else
    echo Ignoring cache
    time sudo docker build . -t ${image_name_and_tag} --progress=plain --no-cache \
    --build-arg IMAGE_PYTHON_VERSION={{python-version}}
  fi
  echo ---------------------------------------
  echo Testing container
  sudo docker container run --rm -it --mount type=volume,source=${temp_volume_name},target=/workspace ${image_name_and_tag} bin/zsh -c "source ~/.zshrc && dc check-container"
  sudo docker volume rm -f ${temp_volume_name} 2> /dev/null 1> /dev/null || true
  echo Image ${image_name_and_tag} built successfully

# Build all images.
build-images no-cache="": (build-image "3.9" no-cache) (build-image "3.10" no-cache) (build-image "3.11" no-cache) (build-image "3.12" no-cache) (build-image "3.13" no-cache)

build-and-upload-image python-version no-cache="":
  sudo docker login
  @echo ---------------------------------------
  just build-image {{python-version}} {{no-cache}}
  @echo ---------------------------------------
  sudo docker push "{{image_name}}:{{python-version}}"
  echo Image "{{image_name}}:{{python-version}}" uploaded successfully

build-and-upload-images no-cache="": (build-and-upload-image "3.9" no-cache) (build-and-upload-image "3.10" no-cache) (build-and-upload-image "3.11" no-cache) (build-and-upload-image "3.12" no-cache) (build-and-upload-image "3.13" no-cache)

connect-to-image python-version:
  #!/usr/bin/env bash
  set -exuo pipefail
  image_name_and_tag="{{image_name}}:{{python-version}}"
  temp_volume_name=temp-volume-for-check-container-{{python-version}}
  sudo docker container run --rm -it --mount type=volume,source=${temp_volume_name},target=/workspace ${image_name_and_tag} bin/zsh

set allow-duplicate-recipes := true
# set allow-duplicate-valiables := true

import "./files/usr/local/share/dev-container/.justfile"
