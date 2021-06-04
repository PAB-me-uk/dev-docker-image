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

RUN apt-get update \
    && export DEBIAN_FRONTEND=noninteractive \
    # Remove imagemagick due to https://security-tracker.debian.org/tracker/CVE-2019-10131
    && apt-get purge -y imagemagick imagemagick-6-common \
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
    # Install terraform
    && wget -nv https://apt.releases.hashicorp.com/gpg  \
    && apt-key add gpg \
    && rm gpg \
    && apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    && apt-get update \
    && apt-get install -y terraform \
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
#    Install awsume
#    Switch to zsh
#    Install python dependencies
#    Install nvm & nodejs lts
#    Prevent vscode touching know_hosts
RUN su - ${USER_NAME} -c "pipx install awsume \
    && ~/.local/bin/awsume-configure --shell zsh --autocomplete-file ~/.zshrc --alias-file ~/.zshrc \
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

