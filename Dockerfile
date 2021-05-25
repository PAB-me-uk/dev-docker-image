FROM registry.fedoraproject.org/fedora:34

RUN cd /tmp \
    && dnf install -y sudo git which wget unzip nano nodejs \
    && dnf install -y python3.6 pipx \
    && wget -nv https://bootstrap.pypa.io/get-pip.py \
    && python3.6 get-pip.py \
    && rm /tmp/get-pip.py \
    && wget -nv https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip \
    && unzip -q awscli-exe-linux-x86_64.zip \
    && /bin/bash ./aws/install \
    && rm -rf /tmp/aws
    # && /usr/local/bin/python -m pip install --upgrade pip

# UID must match volume perms
ARG USER_UID=1000
ARG USER_GID=1000

RUN groupadd -g $USER_GID usersg \
    && adduser dev -u $USER_UID -g $USER_GID -d /home/dev \
    && echo "dev ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/dev \
    && chmod 0440 /etc/sudoers.d/dev

RUN su - dev -c "pipx install awsume && awsume-configure --autocomplete-file ~/.bashrc --shell bash --alias-file ~/.bashrc"
# RUN su - dev -c "echo \"cd ~\" >> ~/.bashrc"

RUN mkdir /home/dev/projects \
    && chown $USER_UID:$USER_GID /home/dev/projects \
    && chmod 0777 /home/dev/projects \
    && chmod g+s /home/dev/projects

VOLUME /home/dev/projects

USER dev
# CMD ["su", "-", "user", "-c", "tail -f /dev/null"]
CMD ["tail", "-f", "/dev/null"]
