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

# install-just version: create-temp-dir && remove-temp-dir
#   #! /bin/bash
#   set -eox pipefail
#   cd {{temp-dir}}
#   wget -qO just.tar.gz https://github.com/casey/just/releases/download/{{version}}/just-{{version}}-x86_64-unknown-linux-musl.tar.gz
#   sudo tar -xvf --overwrite just.tar.gz -C /usr/local/bin just

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
