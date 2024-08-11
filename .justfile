# Load .env file to populate all envars.
set dotenv-load

home := `echo "${HOME}"`
root_dir := justfile_directory()

image_name := "pabuk/dev-python"
default-terraform-version := "1.5.7"
default-tflint-version :=  "0.52.0"

# Default recipe, runs if you just type `just`.
[private]
default:
  just --list

# Build a single image
build-image python-version no-cache="" terraform-version="" tflint-version="":
  #!/usr/bin/env bash
  set -euo pipefail
  image_name_and_tag="{{image_name}}:{{python-version}}"
  temp_volume_name=temp-volume-for-check-container-{{python-version}}
  sudo docker volume rm -f ${temp_volume_name} 2> /dev/null 1> /dev/null || true

  if [[ -z "{{terraform-version}}" ]]; then
    terraform_version="{{default-terraform-version}}"
  else
    terraform_version="{{terraform-version}}"
    image_name_and_tag="${image_name_and_tag}-tf-${terraform_version}"
  fi

  if [[ -z "{{tflint-version}}" ]]; then
    tflint_version="{{default-tflint-version}}"
  else
    tflint_version="{{tflint-version}}"
    image_name_and_tag="${image_name_and_tag}-tfl-${tflint_version}"
  fi

  echo Building image ${image_name_and_tag} with python version: {{python-version}}
  # export DOCKER_BUILDKIT=0
  export COMPOSE_DOCKER_CLI_BUILD=0
  if [[ -z "{{no-cache}}" ]]; then
    echo Using cache
    time sudo docker build . -t ${image_name_and_tag} --progress=plain  \
    --build-arg IMAGE_PYTHON_VERSION={{python-version}} \
    --build-arg IMAGE_TERRAFORM_VERSION=${terraform_version} \
    --build-arg IMAGE_TFLINT_VERSION=${tflint_version}
  else
    echo Ignoring cache
    time sudo docker build . -t ${image_name_and_tag} --progress=plain --no-cache
    --build-arg IMAGE_PYTHON_VERSION={{python-version}} \
    --build-arg IMAGE_TERRAFORM_VERSION=${terraform_version} \
    --build-arg IMAGE_TFLINT_VERSION=${tflint_version}
  fi
  echo ---------------------------------------
  echo Testing container
  sudo docker container run --rm -it --mount type=volume,source=${temp_volume_name},target=/workspace ${image_name_and_tag} bin/zsh -c "source ~/.zshrc && check-container"
  sudo docker volume rm -f ${temp_volume_name} 2> /dev/null 1> /dev/null || true
  echo Image ${image_name_and_tag} built successfully

# Build all images.
build-images no-cache="": (build-image "3.8" no-cache) (build-image "3.9" no-cache) (build-image "3.10" no-cache) (build-image "3.11" no-cache) (build-image "3.12" no-cache)

build-and-upload-image python-version no-cache="":
  sudo docker login
  @echo ---------------------------------------
  just build-image {{python-version}} {{no-cache}}
  @echo ---------------------------------------
  sudo docker push "{{image_name}}:{{python-version}}"
  echo Image "{{image_name}}:{{python-version}}" uploaded successfully

build-and-upload-images no-cache="": (build-and-upload-image "3.8" no-cache) (build-and-upload-image "3.9" no-cache) (build-and-upload-image "3.10" no-cache) (build-and-upload-image "3.11" no-cache) (build-and-upload-image "3.12" no-cache)

connect-to-image python-version:
  #!/usr/bin/env bash
  set -exuo pipefail
  image_name_and_tag="{{image_name}}:{{python-version}}"
  temp_volume_name=temp-volume-for-check-container-{{python-version}}
  sudo docker container run --rm -it --mount type=volume,source=${temp_volume_name},target=/workspace ${image_name_and_tag} bin/zsh


# @todo

# ./home/.local/bin/create-dev-container
# ./home/.local/bin/check-container

# ./connect-to-container.sh
# ./connect-to-docker-host.sh
# ./customise/create-custom-dev-container.sh
# ./home/.local/bin/black-off
# ./home/.local/bin/black-on

# Done

# ./build-image.sh
# ./build-all-images.sh
# ./build-and-upload-image.sh
# ./build-and-upload-all-images.sh

# Skip?

# ./bin/install-apt-packages.sh
# ./bin/install-python-packages.sh
# ./bin/install-vscode-extensions.sh