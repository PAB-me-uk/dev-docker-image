ARG IMAGE_PYTHON_VERSION=3.9
FROM python:${IMAGE_PYTHON_VERSION}
ARG USER_NAME=dev
ARG GROUP_NAME=${USER_NAME}
ARG USER_HOME=/home/${USER_NAME}
ARG USER_UID=1000
ARG USER_GID=1000
ARG DEPENDENCIES_DIR=/var/dependencies
ARG WORKSPACE_DIR=/workspace
ARG CUSTOMISE_DIR=${USER_HOME}/customise

# Expose as envars for use in container or in child images
ENV IMAGE_PYTHON_VERSION=${IMAGE_PYTHON_VERSION}
ENV IMAGE_USER_NAME=${USER_NAME}
ENV IMAGE_GROUP_NAME=${GROUP_NAME}
ENV IMAGE_USER_HOME=${USER_HOME}
ENV IMAGE_USER_UID=${USER_UID}
ENV IMAGE_USER_GID=${USER_GID}
ENV IMAGE_WORKSPACE_DIR=${WORKSPACE_DIR}
ENV IMAGE_CUSTOMISE_DIR=${CUSTOMISE_DIR}

COPY dependencies/packages.txt ${DEPENDENCIES_DIR}/
COPY bin/install-apt-packages.sh /usr/local/bin/

SHELL ["/bin/bash", "-c"]

RUN export DEBIAN_FRONTEND=noninteractive \
    # Remove imagemagick due to https://security-tracker.debian.org/tracker/CVE-2019-10131
    && apt-get purge -y imagemagick imagemagick-6-common \
    # Install packages
    && install-apt-packages.sh ${DEPENDENCIES_DIR}/packages.txt \
    # Install Terraform and Docker
    && wget -nv https://apt.releases.hashicorp.com/gpg && apt-key add gpg && rm gpg \
    && apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    && wget -nv https://download.docker.com/linux/debian/gpg && apt-key add gpg && rm gpg \
    && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
    && apt-get update \
    && apt-get install -y terraform docker-ce-cli \
    # Install AWS CLI
    && cd /tmp \
    && wget -nv https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip \
    && unzip -q awscli-exe-linux-x86_64.zip \
    && rm awscli-exe-linux-x86_64.zip \
    && /bin/bash ./aws/install \
    && rm -rf /tmp/aws \
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

COPY dependencies/* ${DEPENDENCIES_DIR}/

COPY bin/* /usr/local/bin/

SHELL ["/bin/zsh", "-c"]

# Run as user
#   Switch to zsh
#   Install pipx depedancies
#   Configure awsume
#   Install python dependencies
#   Install nvm & nodejs lts
#   Prevent vscode touching known_hosts
RUN su - ${USER_NAME} -c "\
    export PATH=\"${USER_HOME}/.local/bin/:${PATH}\" \
    && printf \"zsh\\n\" >> ~/.bashrc \
    && pip install --user --no-cache-dir -r ${DEPENDENCIES_DIR}/requirements.txt \
    && install-pipx-packages.sh ${DEPENDENCIES_DIR}/pipx.txt \
    && ~/.local/bin/awsume-configure --shell zsh --autocomplete-file ~/.zshrc --alias-file ~/.zshrc \
    && sudo ln -s ${USER_HOME}/.local/bin/cfn-lint /usr/local/bin/cfn-lint \
    && sudo ln -s ${USER_HOME}/.local/bin/prospector /usr/local/bin/prospector \
    && sudo ln -s ${USER_HOME}/.local/bin/autopep8 /usr/local/bin/autopep8 \
    && sudo ln -s ${USER_HOME}/.local/bin/check-container.py /usr/local/bin/check-container \
    && cd /tmp \
    && wget -nv https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh \
    && zsh ./install.sh \
    && . ~/.nvm/nvm.sh \
    && nvm install --lts \
    && nvm alias default node \
    && nvm cache clear \
    && rm install.sh \
"

# Copy customisation files to user home
COPY --chown=${USER_UID} customise/. ${USER_HOME}/customise/

# Run container as user
USER ${USER_NAME}
# Keep container running
CMD ["tail", "-f", "/dev/null"]
