ARG IMAGE_PYTHON_VERSION=3.12
# Arguments added above the FROM line are not available after the FROM line unless redefined after
FROM python:${IMAGE_PYTHON_VERSION}
ARG IMAGE_PYTHON_VERSION=3.12
ARG TIMEZONE=Europe/London
ARG USER_NAME=dev
ARG GROUP_NAME=${USER_NAME}
ARG USER_HOME=/home/${USER_NAME}
ARG USER_HOME_BIN=${USER_HOME}/.local/bin
ARG USER_UID=1000
ARG USER_GID=1000
ARG DEPENDENCIES_DIR=/var/dependencies
ARG WORKSPACE_DIR=/workspace
ARG WORKSPACE_TEMPLATE_DIR=/.workspace
ARG CUSTOMISE_DIR=${USER_HOME}/customise

# Expose as envars for use in container or in child images
ENV IMAGE_PYTHON_VERSION=${IMAGE_PYTHON_VERSION}
ENV IMAGE_USER_NAME=${USER_NAME}
ENV IMAGE_GROUP_NAME=${GROUP_NAME}
ENV IMAGE_USER_HOME=${USER_HOME}
ENV IMAGE_USER_HOME_BIN=${USER_HOME_BIN}
ENV IMAGE_USER_UID=${USER_UID}
ENV IMAGE_USER_GID=${USER_GID}
ENV IMAGE_WORKSPACE_DIR=${WORKSPACE_DIR}
ENV IMAGE_WORKSPACE_TEMPLATE_DIR=${WORKSPACE_TEMPLATE_DIR}
ENV IMAGE_CUSTOMISE_DIR=${CUSTOMISE_DIR}
ENV IMAGE_TERRAFORM_VERSION=1.5.7
ENV IMAGE_JUST_VERSION=1.23.0

COPY dependencies/* ${DEPENDENCIES_DIR}/
COPY bin/* /usr/local/bin/

SHELL ["/bin/bash", "-c"]

RUN export DEBIAN_FRONTEND=noninteractive \
    # Set timezone
    && ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    # Remove imagemagick due to https://security-tracker.debian.org/tracker/CVE-2019-10131
    && apt-get purge -y imagemagick imagemagick-6-common \
    # Install packages
    && install-apt-packages.sh ${DEPENDENCIES_DIR}/packages.txt \
    # Install Docker
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y docker-ce-cli docker-compose-plugin ruby-dev \
    # Install Terraform
    && wget -q https://releases.hashicorp.com/terraform/${IMAGE_TERRAFORM_VERSION}/terraform_${IMAGE_TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip -q terraform_${IMAGE_TERRAFORM_VERSION}_linux_amd64.zip \
    && rm terraform_1.5.7_linux_amd64.zip \
    && mv terraform /usr/bin/ \
    # Old version which gets latest Terraform version.
    # && wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor > /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    # && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" > /etc/apt/sources.list.d/hashicorp.list \
    # && apt-get install -y terraform  \
    # Install AWS CLI
    && cd /tmp \
    && wget -q https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip \
    && unzip -q awscli-exe-linux-x86_64.zip \
    && rm awscli-exe-linux-x86_64.zip \
    && /bin/bash ./aws/install \
    && rm -rf ./aws \
    # Install AWS SAM CLI
    && wget -q https://github.com/aws/aws-sam-cli/releases/latest/download/aws-sam-cli-linux-x86_64.zip \
    && unzip -q aws-sam-cli-linux-x86_64.zip -d sam-installation \
    && rm aws-sam-cli-linux-x86_64.zip \
    && /bin/bash ./sam-installation/install \
    && rm -rf ./sam-installation \
    # Install Session Manager Plugin
    && wget -q https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb \
    && dpkg -i session-manager-plugin.deb \
    && rm session-manager-plugin.deb \
    # Install GitHub CLI
    && wget -q https://github.com/cli/cli/releases/download/v2.22.1/gh_2.22.1_linux_amd64.deb \
    && dpkg -i gh_2.22.1_linux_amd64.deb \
    && rm gh_2.22.1_linux_amd64.deb \
    # Install cfn-nag
    && gem install cfn-nag \
    # Install Dart Sass
    && wget -q https://github.com/sass/dart-sass/releases/download/1.58.0/dart-sass-1.58.0-linux-x64.tar.gz \
    && tar -xvf dart-sass-1.58.0-linux-x64.tar.gz \
    && rm dart-sass-1.58.0-linux-x64.tar.gz \
    && mv dart-sass/sass /usr/local/bin/ \
    && mv dart-sass/src /usr/local/bin/ \
    && rm -rf dart-sass \
    # Install steampipe
    && wget -q https://github.com/turbot/steampipe/releases/latest/download/steampipe_linux_amd64.tar.gz \
    && tar -xvf steampipe_linux_amd64.tar.gz \
    && rm steampipe_linux_amd64.tar.gz \
    && mv steampipe /usr/local/bin/ \
    # Install Biome
    && wget -q https://github.com/biomejs/biome/releases/download/cli%2Fv1.8.2/biome-linux-x64 \
    && mv biome-linux-x64 /usr/local/bin/biome \
    && chmod +x /usr/local/bin/biome \
    # Install Just
    && wget -q https://github.com/casey/just/releases/download/${IMAGE_JUST_VERSION}/just-${IMAGE_JUST_VERSION}-x86_64-unknown-linux-musl.tar.gz \
    && tar -xvf just-${IMAGE_JUST_VERSION}-x86_64-unknown-linux-musl.tar.gz -C /usr/local/bin just \
    && rm just-${IMAGE_JUST_VERSION}-x86_64-unknown-linux-musl.tar.gz \
    # Create user and group, allow sudo
    && groupadd --gid ${USER_GID} ${GROUP_NAME} \
    && adduser --gid ${USER_GID} --uid ${USER_UID} --home ${USER_HOME} --disabled-password --gecos "" ${USER_NAME} \
    && usermod --groups sudo  --shell /usr/bin/zsh ${USER_NAME} \
    && echo "${USER_NAME} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USER_NAME} \
    && chmod 0440 /etc/sudoers.d/${USER_NAME} \
    # Configure workspace
    && mkdir ${WORKSPACE_DIR} \
    && chown ${USER_UID}:${USER_GID} ${WORKSPACE_DIR} \
    && chmod 0755 ${WORKSPACE_DIR} \
    && chmod g+s ${WORKSPACE_DIR} \
    # Configure workspace template
    && mkdir ${WORKSPACE_TEMPLATE_DIR} \
    && chown ${USER_UID}:${USER_GID} ${WORKSPACE_TEMPLATE_DIR} \
    && chmod 0755 ${WORKSPACE_TEMPLATE_DIR} \
    && chmod g+s ${WORKSPACE_TEMPLATE_DIR} \
    # Configure ~/.ssh
    && mkdir ${USER_HOME}/.ssh \
    && chown ${USER_UID}:${USER_GID} ${USER_HOME}/.ssh \
    && chmod 0700 ${USER_HOME}/.ssh \
    # Configure ~/.aws
    && mkdir ${USER_HOME}/.aws \
    && chown ${USER_UID}:${USER_GID} ${USER_HOME}/.aws \
    && chmod 0700 ${USER_HOME}/.aws

# Copy files to user home, including subdirectories
COPY --chown=${USER_UID} home/. ${USER_HOME}/

SHELL ["/bin/zsh", "-c"]
# Run as user
#   Switch to zsh
#   Install python pip dependencies
#   Install python pipx depedancies
#   Install steampip plugins
#   Install nvm
#   Install zsh autosuggestions
RUN su - ${USER_NAME} -c "\
    export PATH=\"${USER_HOME}/.local/bin/:${PATH}\" \
    && printf \"zsh\\n\" >> ~/.bashrc \
    && install-python-packages.sh ${DEPENDENCIES_DIR} ${IMAGE_WORKSPACE_DIR} ${IMAGE_WORKSPACE_TEMPLATE_DIR} ${IMAGE_PYTHON_VERSION} \
    && steampipe plugin install aws awscfn terraform jira \
    && cd /tmp \
    && wget -q https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh \
    && bash ./install.sh \
    && . ~/.nvm/nvm.sh \
    && nvm install --lts \
    && nvm alias default node \
    && nvm cache clear \
    && rm install.sh \
    && mkdir -p ~/.zsh \
    && git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions \
    && mkdir -p ~/.just/zsh-autocomplete \
    && just --completions zsh > ~/.just/zsh-autocomplete/_just \
    && ~/.local/bin/awsume-configure --shell zsh \
    "

# Copy customisation files to user home
COPY --chown=${USER_UID} customise/. ${USER_HOME}/customise/

RUN sed -i "s|\${env:IMAGE_PYTHON_VERSION}|${IMAGE_PYTHON_VERSION}|g" ${USER_HOME}/.vscode-server/data/Machine/settings.json \
    && sed -i "s|\${env:IMAGE_USER_HOME_BIN}|${IMAGE_USER_HOME_BIN}|g" ${USER_HOME}/.vscode-server/data/Machine/settings.json

# Run container as user
USER ${USER_NAME}
# Keep container running
CMD ["tail", "-f", "/dev/null"]
