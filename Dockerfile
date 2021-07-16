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
ARG WORKSPACE_DIR=/work
ARG WORKSPACE_TEMPLATE_DIR=/.work
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

COPY dependencies/packages.txt ${DEPENDENCIES_DIR}/
COPY bin/install-apt-packages.sh /usr/local/bin/

SHELL ["/bin/bash", "-c"]

RUN export DEBIAN_FRONTEND=noninteractive \
    # Set timezone
    && ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    # Remove imagemagick due to https://security-tracker.debian.org/tracker/CVE-2019-10131
    && apt-get purge -y imagemagick imagemagick-6-common \
    # Install packages
    && install-apt-packages.sh ${DEPENDENCIES_DIR}/packages.txt \
    # Install Terraform and Docker
    && wget -q https://apt.releases.hashicorp.com/gpg && apt-key add gpg && rm gpg \
    && apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    && wget -q https://download.docker.com/linux/debian/gpg && apt-key add gpg && rm gpg \
    && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
    && apt-get update \
    && apt-get install -y terraform docker-ce-cli \
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
    # Install cfn-nag
    && gem install cfn-nag \
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

# Run as user
#   Install nvm & nodejs lts
RUN su - ${USER_NAME} -c "\
    cd /tmp \
    && wget -q https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh \
    && zsh ./install.sh \
    && . ~/.nvm/nvm.sh \
    && nvm install --lts \
    && nvm alias default node \
    && nvm cache clear \
    && rm install.sh \
"

COPY dependencies/* ${DEPENDENCIES_DIR}/

COPY bin/* /usr/local/bin/

SHELL ["/bin/zsh", "-c"]

# Run as user
#   Switch to zsh
#   Install python pip dependencies
#   Install python pipx depedancies
#   Configure awsume
RUN su - ${USER_NAME} -c "\
    export PATH=\"${USER_HOME}/.local/bin/:${PATH}\" \
    && printf \"zsh\\n\" >> ~/.bashrc \
    && install-python-packages.sh ${DEPENDENCIES_DIR} ${IMAGE_WORKSPACE_DIR} ${IMAGE_WORKSPACE_TEMPLATE_DIR} ${IMAGE_PYTHON_VERSION} \
    && ~/.local/bin/awsume-configure --shell zsh --autocomplete-file ~/.zshrc --alias-file ~/.zshrc \
"

# Copy customisation files to user home
COPY --chown=${USER_UID} customise/. ${USER_HOME}/customise/

RUN sed -i "s|\${env:IMAGE_PYTHON_VERSION}|${IMAGE_PYTHON_VERSION}|g" ${USER_HOME}/.vscode-server/data/Machine/settings.json \
    && sed -i "s|\${env:IMAGE_USER_HOME_BIN}|${IMAGE_USER_HOME_BIN}|g" ${USER_HOME}/.vscode-server/data/Machine/settings.json

RUN echo ${IMAGE_WORKSPACE_DIR} xxxx

# Run container as user
USER ${USER_NAME}
# Keep container running
CMD ["tail", "-f", "/dev/null"]
