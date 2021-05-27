ARG PYTHON_VERSION=3.9
FROM python:${PYTHON_VERSION}

RUN apt-get update \
    && export DEBIAN_FRONTEND=noninteractive \
    # Remove imagemagick due to https://security-tracker.debian.org/tracker/CVE-2019-10131
    && apt-get purge -y imagemagick imagemagick-6-common \
    && apt-get install -y apt-utils \
    && apt-get install -y zsh sudo nano less nodejs pipx python3-venv \
    && touch /etc/gitconfig

  RUN cd /tmp \
      && wget -nv https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip \
      && unzip -q awscli-exe-linux-x86_64.zip \
      && /bin/bash ./aws/install \
      && rm -rf /tmp/aws

# UID must match volume perms
ARG USER_UID=1000
ARG USER_GID=1000

RUN groupadd --gid $USER_GID dev \
    && adduser --gid $USER_GID --uid $USER_UID --home /home/dev --disabled-password --gecos "" dev \
    && usermod --groups sudo  --shell /usr/bin/zsh dev \
    && echo "dev ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/dev \
    && chmod 0440 /etc/sudoers.d/dev

COPY --chown=dev files/.zshrc /home/dev/.zshrc

RUN su - dev -c "pipx install awsume && ~/.local/bin/awsume-configure --shell zsh --autocomplete-file ~/.zshrc --alias-file ~/.zshrc"
RUN su - dev -c "printf \"zsh\" >> ~/.bashrc && touch ~/.gitconfig"


RUN mkdir /home/dev/projects \
    && chown $USER_UID:$USER_GID /home/dev/projects \
    && chmod 0755 /home/dev/projects \
    && chmod g+s /home/dev/projects

COPY --chown=dev files/fixgit.sh /home/dev/.local/bin/fixgit

USER dev
CMD ["tail", "-f", "/dev/null"]
