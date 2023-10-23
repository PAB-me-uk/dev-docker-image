ARG IMAGE_PYTHON_VERSION=3.9
# Arguments added above the FROM line are not available after the FROM line unless redefined after
FROM python:${IMAGE_PYTHON_VERSION}
ARG IMAGE_PYTHON_VERSION=3.9
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
    # Install Terraform and Docker
    && wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor > /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" > /etc/apt/sources.list.d/hashicorp.list

RUN wget -q https://download.docker.com/linux/debian/gpg && apt-key add gpg && rm gpg \
    && add-apt-repository "deb [arch=arm64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y terraform docker-ce-cli docker-compose-plugin ruby-dev

# Install AWS CLI
RUN cd /tmp \
    && wget -q https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip \
    && unzip -q awscli-exe-linux-aarch64.zip \
    && rm awscli-exe-linux-aarch64.zip \
    && /bin/bash ./aws/install \
    && rm -rf ./aws

# # Install AWS SAM CLI - #### linux arm64 zip not available JvS 23/10/23
# "We recommend installing the AWS SAM CLI into a virtual environment... using pip."
RUN pip install --upgrade aws-sam-cli
#### but "WARNING: Running pip as the 'root' user can result in broken permissions and conflicting behaviour with the system package manager. It is recommended to use a virtual environment instead: https://pip.pypa.io/warnings/venv"
# Install Session Manager Plugin
RUN wget -q "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_arm64/session-manager-plugin.deb" \
    && dpkg -i session-manager-plugin.deb

# # Install GitHub CLI
#### gh_2.22.1_linux_arm64.rpm' is not a Debian format archive
# RUN wget -q https://github.com/cli/cli/releases/download/v2.22.1/gh_2.22.1_linux_arm64.rpm \
#     && dpkg -i gh_2.22.1_linux_arm64.rpm \
#     && rm gh_2.22.1_linux_arm64.rpm

# Install cfn-nag
RUN gem install cfn-nag \
    # Install Dart Sass
    && wget -q https://github.com/sass/dart-sass/releases/download/1.58.0/dart-sass-1.58.0-linux-arm64.tar.gz \
    && tar -xvf dart-sass-1.58.0-linux-arm64.tar.gz \
    && rm dart-sass-1.58.0-linux-arm64.tar.gz \
    && mv dart-sass/sass /usr/local/bin/ \
    && mv dart-sass/src /usr/local/bin/ \
    && rm -rf dart-sass

# Install steampipe
RUN wget -q https://github.com/turbot/steampipe/releases/download/v0.21.1/steampipe_linux_arm64.tar.gz \
    && tar -xvf steampipe_linux_arm64.tar.gz \
    && rm steampipe_linux_arm64.tar.gz \
    && mv steampipe /usr/local/bin/ \
    # Install Just
    && install-just.sh --to /usr/local/bin

# Create user and group, allow sudo
RUN groupadd --gid ${USER_GID} ${GROUP_NAME} \
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
    && wget -q https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh \
    && bash ./install.sh \
    && . ~/.nvm/nvm.sh \
    && nvm install --lts \
    && nvm alias default node \
    && nvm cache clear \
    && rm install.sh \
    && mkdir -p ~/.zsh \
    && git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions \
    && ~/.local/bin/awsume-configure --shell zsh \
    && mkdir -p ~/.just/zsh-autocomplete \
    && just --completions zsh > ~/.just/zsh-autocomplete/_just \
    "

# Copy customisation files to user home
COPY --chown=${USER_UID} customise/. ${USER_HOME}/customise/

RUN sed -i "s|\${env:IMAGE_PYTHON_VERSION}|${IMAGE_PYTHON_VERSION}|g" ${USER_HOME}/.vscode-server/data/Machine/settings.json \
    && sed -i "s|\${env:IMAGE_USER_HOME_BIN}|${IMAGE_USER_HOME_BIN}|g" ${USER_HOME}/.vscode-server/data/Machine/settings.json

# Run container as user
USER ${USER_NAME}
# Keep container running
CMD ["tail", "-f", "/dev/null"]
