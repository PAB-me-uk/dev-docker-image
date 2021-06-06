ARG PYTHON_VERSION=3.9
FROM python:${PYTHON_VERSION}

ARG USER_NAME=dev
ARG GROUP_NAME=${USER_NAME}
ARG USER_HOME=/home/${USER_NAME}
ARG USER_UID=1000
ARG USER_GID=1000
ARG DEPENDENCIES=/tmp/dependencies
ARG WORKSPACE=/workspace

COPY dependencies/* ${DEPENDENCIES}/

RUN export DEBIAN_FRONTEND=noninteractive \
    && cd /tmp \
    && apt-get update && apt-get install -y apt-utils software-properties-common \
    # Remove imagemagick due to https://security-tracker.debian.org/tracker/CVE-2019-10131
    && apt-get purge -y imagemagick imagemagick-6-common \
    # Add extra repositries
    && wget -nv https://apt.releases.hashicorp.com/gpg && apt-key add gpg && rm gpg \
    && apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    && wget -nv https://download.docker.com/linux/debian/gpg && apt-key add gpg && rm gpg \
    && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
    && apt-get update \
    # Install packages
    && xargs -a ${DEPENDENCIES}/packages.txt apt-get install -y \
    && rm ${DEPENDENCIES}/packages.txt \
    # Create user and group, allow sudo
    && groupadd --gid ${USER_GID} ${GROUP_NAME} \
    && adduser --gid ${USER_GID} --uid ${USER_UID} --home ${USER_HOME} --disabled-password --gecos "" ${USER_NAME} \
    && usermod --groups sudo  --shell /usr/bin/zsh ${USER_NAME} \
    && echo "${USER_NAME} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USER_NAME} \
    && chmod 0440 /etc/sudoers.d/${USER_NAME} \
    # Install AWS CLI
    && cd /tmp \
    && wget -nv https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip \
    && unzip -q awscli-exe-linux-x86_64.zip \
    && /bin/bash ./aws/install \
    && rm -rf /tmp/aws \
    # Install cfn-nag
    && gem install cfn-nag \
    # Configure workspace
    && mkdir ${WORKSPACE} \
    && chown ${USER_UID}:${USER_GID} ${WORKSPACE} \
    && chmod 0755 ${WORKSPACE} \
    && chmod g+s ${WORKSPACE} \
    # Configure ~/.ssh
    && mkdir ${USER_HOME}/.ssh \
    && chown ${USER_UID}:${USER_GID} ${USER_HOME}/.ssh \
    && chmod 0700 ${USER_HOME}/.ssh \
    # Configure ~/.aws
    && mkdir ${USER_HOME}/.aws \
    && chown ${USER_UID}:${USER_GID} ${USER_HOME}/.aws \
    && chmod 0700 ${USER_HOME}/.aws

# Copy files to user home
COPY --chown=${USER_UID} home/. ${USER_HOME}/

# Run as user
#    Switch to zsh
#    Install pipx depedancies
#    Configure awsume
#    Install python dependencies
#    Install nvm & nodejs lts
#    Prevent vscode touching know_hosts
RUN su - ${USER_NAME} -c "printf \"zsh\" >> ~/.bashrc \
    && grep -v \"^ *#\" ${DEPENDENCIES}/pipx.txt | xargs -I {} -n1 pipx install --python /usr/local/bin/python {} \
    && ~/.local/bin/awsume-configure --shell zsh --autocomplete-file ~/.zshrc --alias-file ~/.zshrc \
    && sudo ln -s ${USER_HOME}/.local/bin/cfn-lint /usr/local/bin/cfn-lint \
    && printf \"zsh\" >> ~/.bashrc \
    && chmod +x ${USER_HOME}/.local/bin/fixgit \
    && chmod +x ${USER_HOME}/.local/bin/versions \
    && pip install -r ${DEPENDENCIES}/requirements.txt --user --no-warn-script-location \
    && sudo rm ${DEPENDENCIES}/requirements.txt \
    && cd /tmp \
    && wget -nv https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh \
    && zsh install.sh \
    && zsh \
    && . ~/.nvm/nvm.sh \
    && nvm install --lts \
    && nvm alias default node \
    && rm install.sh \
    && touch ${USER_HOME}/.ssh/known_hosts"

USER ${USER_NAME}
CMD ["tail", "-f", "/dev/null"]

