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

create-temp-dir:
  mkdir -p {{temp-dir}}

remove-temp-dir
  rm -rf {{temp-dir}}


# Install Terragrunt
install-terragrunt version:
  #! /bin/bash
  set -eox pipefail
  sudo wget -O /usr/local/bin/terragrunt -q https://github.com/gruntwork-io/terragrunt/releases/download/v{{version}}/terragrunt_linux_amd64
  sudo chmod +x /usr/local/bin/terragrunt
  terragrunt --version

# Install Terraform
install-terraform version: create-temp-dir && remove-temp-dir
  #! /bin/bash
  set -eox pipefail
  cd {{temp-dir}}
  wget -O terraform.zip -q https://releases.hashicorp.com/terraform/{{version}}/terraform_{{version}}_linux_amd64.zip
  unzip -qo terraform.zip
  sudo mv -f terraform /usr/bin/
  sudo chmod +x /usr/bin/terraform

# Install TFLint
install-tflint version:  create-temp-dir && remove-temp-dir
  #! /bin/bash
  set -eox pipefail
  cd {{temp-dir}}
  curl -s https://raw.githubusercontent.com/terraform-linters/tflint/v${IMAGE_TFLINT_VERSION}/install_linux.sh | /bin/bash -x


# Install go
install-go version:
  #! /bin/bash
  set -eox pipefail
  temp_dir=/tmp/install-terraform
  mkdir -p ${temp_dir}
  cd ${temp_dir}
  wget -O go.tar.gz -q https://go.dev/dl/go{{version}}.linux-amd64.tar.gz
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf go.tar.gz
  if ! grep -Fxq 'export PATH=$PATH:/usr/local/go/bin' ~/.zshrc; then
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.zshrc
  fi
  . ~/.zshrc
  rm -rf ${temp_dir}
  go version

install-just version:
  #! /bin/bash
  set -eox pipefail
  temp_dir=/tmp/install-just
  mkdir -p ${temp_dir}
  cd ${temp_dir}
  wget -q https://github.com/casey/just/releases/download/{{version}}/just-{{version}}-x86_64-unknown-linux-musl.tar.gz
  sudo tar -xvf --overwrite just-{{version}}-x86_64-unknown-linux-musl.tar.gz -C /usr/local/bin just
  rm -rf ${temp_dir}

install-biome version:
  #! /bin/bash
  set -eox pipefail
  sudo wget -O /usr/local/bin/biome -q https://github.com/biomejs/biome/releases/download/cli%2Fv{{version}}/biome-linux-x64
  sudo chmod +x /usr/local/bin/biome
