ARG PYTHON_VERSION=3.9
FROM python:${PYTHON_VERSION}

RUN apt-get update \
    && export DEBIAN_FRONTEND=noninteractive \
    # Remove imagemagick due to https://security-tracker.debian.org/tracker/CVE-2019-10131
    && apt-get purge -y imagemagick imagemagick-6-common \
    && apt-get install -y apt-utils \
    && apt-get install -y sudo nano less nodejs pipx python3-venv

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
    && usermod -aG sudo dev \
    && echo "dev ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/dev \
    && chmod 0440 /etc/sudoers.d/dev


RUN su - dev -c "pipx install awsume && ~/.local/bin/awsume-configure --autocomplete-file ~/.bashrc --shell bash --alias-file ~/.bashrc"
RUN su - dev -c "printf \"export PATH=\\\"~/.local/bin/:$PATH\\\"\\ncd ~/projects\" >> ~/.bashrc"

RUN mkdir /home/dev/projects \
    && chown $USER_UID:$USER_GID /home/dev/projects \
    && chmod 0755 /home/dev/projects \
    && chmod g+s /home/dev/projects

USER dev
CMD ["tail", "-f", "/dev/null"]
