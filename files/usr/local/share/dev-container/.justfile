# .justfile contains commands to be run by the `just` command line tool.
# https://just.systems/man/en/

workspace-path := "/workspace"
aws-profile := "calypso-dev-us"
terrform-state-bucket := "nonprod-terraform-state-a3kgzd7g"

temp-dir := "/tmp/dc-temp-dir"

# Default recipe, runs if you just type `just`.
[private]
default:
  just --list --color always | less -R

# Edit the current .justfile
edit:
  code {{justfile()}}

[private]
create-temp-dir: remove-temp-dir
  mkdir -p {{temp-dir}}

[private]
remove-temp-dir:
  rm -rf {{temp-dir}}

# Install Terragrunt
install-terragrunt version:
  #! /bin/bash
  set -eox pipefail
  sudo wget -qO /usr/local/bin/terragrunt https://github.com/gruntwork-io/terragrunt/releases/download/v{{version}}/terragrunt_linux_amd64
  sudo chmod +x /usr/local/bin/terragrunt
  terragrunt --version

# Install Terraform
install-terraform version: create-temp-dir && remove-temp-dir
  #! /bin/bash
  set -eox pipefail
  cd {{temp-dir}}
  wget -qO terraform.zip https://releases.hashicorp.com/terraform/{{version}}/terraform_{{version}}_linux_amd64.zip
  unzip -qo terraform.zip
  sudo mv -f terraform /usr/bin/
  sudo chmod +x /usr/bin/terraform

# Install TFLint
install-tflint version: create-temp-dir && remove-temp-dir
  #! /bin/bash
  set -eox pipefail
  cd {{temp-dir}}
  curl -s https://raw.githubusercontent.com/terraform-linters/tflint/v${IMAGE_TFLINT_VERSION}/install_linux.sh | /bin/bash -x


# Install go
install-go version: create-temp-dir && remove-temp-dir
  #! /bin/bash
  set -eox pipefail
  cd {{temp-dir}}
  wget -qO go.tar.gz https://go.dev/dl/go{{version}}.linux-amd64.tar.gz
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf go.tar.gz
  if ! grep -Fxq 'export PATH=$PATH:/usr/local/go/bin' ~/.zshrc; then
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.zshrc
  fi
  . ~/.zshrc
  go version

# Install Biome
install-biome version:
  #! /bin/bash
  set -eox pipefail
  sudo wget -O /usr/local/bin/biome -q https://github.com/biomejs/biome/releases/download/cli%2Fv{{version}}/biome-linux-x64
  sudo chmod +x /usr/local/bin/biome

# Install GitHub CLI
install-github-cli version: create-temp-dir && remove-temp-dir
  #! /bin/bash
  set -eox pipefail
  cd {{temp-dir}}
  wget -qO gh.deb https://github.com/cli/cli/releases/download/v{{version}}/gh_{{version}}_linux_amd64.deb
  dpkg -i gh.deb

# Install Dart Sass
install-dart-sass version: create-temp-dir && remove-temp-dir
  wget -qO dart-sass.tar.gz https://github.com/sass/dart-sass/releases/download/{{version}}/dart-sass-{{version}}-linux-x64.tar.gz
  tar -xvf dart-sass.tar.gz
  mv dart-sass/sass /usr/local/bin/
  mv dart-sass/src /usr/local/bin/

# Create dev container
create-dev-container container-name volume-name python-version *other-home-directories-to-map:
  #!/bin/bash
  set -eo pipefail
  home_mounts=({{other-home-directories-to-map}})
  home_mounts+=('.ssh' '.aws')
  home_mount_arguments=""
  echo Home directory mounts are: ${home_mounts[*]}
  for mount in "${home_mounts[@]}"; do
    home_mount_arguments+=" --mount type=bind,source=${HOST_USER_HOME}/${mount},target=/home/dev/${mount}"
  done

  echo Deleting any existing container with name: {{container-name}}
  sudo docker container rm -f {{container-name}} 2> /dev/null 1> /dev/null || true
  mkdir -p ~/.ssh
  mkdir -p ~/.aws

  if [[ -z "${NO_PULL}" ]]; then
    echo Getting latest image
    sudo docker pull pabuk/dev-python:{{python-version}}
  fi

  echo Creating container with name: {{container-name}}

  command="docker container run -d
    --name {{container-name}} \
    --mount type=volume,source={{volume-name}},target=${IMAGE_WORKSPACE_DIR} \
    --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
    ${home_mount_arguments} \
    --env HOST_USER_HOME=${HOST_USER_HOME} \
    pabuk/dev-python:{{python-version}}"
  echo Command: $command
  eval sudo $command
  echo Container created with name: {{container-name}}

  # Backwards compatability:

  # Check if .zsh-extra is in home_mounts
  found=0
  for mount in "${home_mounts[@]}"; do
      if [[ $mount == ".zsh-extra" ]]; then
          found=1
          break
      fi
  done

  # If .zsh-extra is not in home_mounts, and if the .zsh-extra directory exists, copy it to the new container
  if [[ $found -eq 0 ]] && [[ -d ${HOME}/.zsh-extra ]]; then
    sudo docker cp ${HOME}/.zsh-extra {{container-name}}:${HOME}/
    echo Copied ${HOME}/.zsh-extra to new container
  fi

# Check container
check-container:
  python check-container.py

connect-to-host:
  sudo docker run -it --rm --privileged --pid=host alpine:edge nsenter -t 1 -m -u -n -i bin/bash

python-formatter-black:
  #!/bin/bash
  set -e
  settings_file=/home/dev/.vscode-server/data/Machine/settings.json
  tmp=$(mktemp)
  jq '."python.formatting.provider" = "black"' ${settings_file} > "${tmp}" && mv "${tmp}" ${settings_file}
  grep "python\.formatting\.provider" ${settings_file}

python-formatter-autopep8:
  #!/bin/bash
  set -e
  settings_file=/home/dev/.vscode-server/data/Machine/settings.json
  tmp=$(mktemp)
  jq '."python.formatting.provider" = "autopep8"' ${settings_file} > "${tmp}" && mv "${tmp}" ${settings_file}
  grep "python\.formatting\.provider" ${settings_file}

versions:
  echo "Python    : $(python --version | awk '{print $NF}')"
  echo "NodeJS    : $(node --version)"
  echo "NPM       : $(npm --version)"
  echo "AWS CLI   : $(aws --version)"
  echo "Awsume    : $(awsume -v 2>&1 | sed -n 2p)"
  echo "Terraform : $(terraform --version | sed -n 1p | awk '{print $2}')"

[private]
install-vscode-extensions:
  code --uninstall-extension rome.rome
  code --uninstall-extension dbaeumer.vscode-eslint
  code --uninstall-extension ms-python.autopep8
  code --uninstall-extension ms-python.isort
  code --install-extension bibhasdn.unique-lines
  code --install-extension biomejs.biome
  code --install-extension charliermarsh.ruff
  code --install-extension esbenp.prettier-vscode
  code --install-extension hashicorp.terraform
  code --install-extension hashicorp.hcl
  code --install-extension kddejong.vscode-cfn-lint
  code --install-extension moshfeu.compare-folders
  code --install-extension ms-python.black-formatter
  code --install-extension ms-python.python
  code --install-extension ms-python.vscode-pylance
  code --install-extension ms-toolsai.jupyter
  code --install-extension oderwat.indent-rainbow
  code --install-extension Orta.vscode-jest
  code --install-extension ryu1kn.partial-diff
  code --install-extension streetsidesoftware.code-spell-checker
  code --install-extension thamaraiselvam.remove-blank-lines
  code --install-extension wmaurer.change-case
