ARG PYTHON_VERSION=3.9
FROM python:${PYTHON_VERSION}

ARG USER_NAME=dev
ARG GROUP_NAME=${USER_NAME}
ARG USER_HOME=/home/${USER_NAME}
ARG USER_UID=1000
ARG USER_GID=1000
ARG WORKSPACE=/workspace

COPY packages/* /tmp/

RUN apt-get update \
    && export DEBIAN_FRONTEND=noninteractive \
    # Remove imagemagick due to https://security-tracker.debian.org/tracker/CVE-2019-10131
    && apt-get purge -y imagemagick imagemagick-6-common \
    # Install packages
    && xargs -a /tmp/packages.txt apt-get install -y \
    && rm /tmp/packages.txt \
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
    # Configure workspace
    && mkdir ${WORKSPACE} \
    && chown ${USER_UID}:${USER_GID} ${WORKSPACE} \
    && chmod 0755 ${WORKSPACE} \
    && chmod g+s ${WORKSPACE} \
    # Configure ~/.ssh
    && mkdir ${USER_HOME}/.ssh \
    && chown ${USER_UID}:${USER_GID} ${USER_HOME}/.ssh \
    && chmod 0400 ${USER_HOME}/.ssh \
    # Configure ~/.aws
    && mkdir ${USER_HOME}/.aws \
    && chown ${USER_UID}:${USER_GID} ${USER_HOME}/.aws \
    && chmod 0600 ${USER_HOME}/.aws \
    # Prevent vscode owning git config
    && touch /etc/gitconfig
    # && chown ${USER_NAME} /tmp/requirements.txt

# Copy files to user home
COPY --chown=${USER_UID} home/* ${USER_HOME}/

# Run as user
#    Install awsume
#    Switch to zsh
#    Prevent vscode owning git config
#    Install python dependancies
#    Install nvm & nodejs lts
RUN su - ${USER_NAME} -c "pipx install awsume \
    && ~/.local/bin/awsume-configure --shell zsh --autocomplete-file ~/.zshrc --alias-file ~/.zshrc \
    && printf \"zsh\" >> ~/.bashrc \
    && touch ~/.gitconfig \
    && cd /tmp \
    && pip install -r requirements.txt --user \
    && sudo rm requirements.txt \
    && wget -nv https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh \
    && zsh install.sh \
    && zsh \
    && . ~/.nvm/nvm.sh \
    && nvm install --lts \
    && nvm alias default node \
    && rm install.sh"



USER ${USER_NAME}
CMD ["tail", "-f", "/dev/null"]
