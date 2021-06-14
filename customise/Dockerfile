ARG IMAGE_PYTHON_VERSION=3.9
FROM pabuk/dev-python:${IMAGE_PYTHON_VERSION}
# DEPENDENCIES_DIR Must not be same as main image (/tmp/dependencies)as will clash
ARG DEPENDENCIES_DIR=/var/custom-dependencies

# Environmental variables available to use in this file from parent image
# IMAGE_USER_NAME
# IMAGE_GROUP_NAME
# IMAGE_USER_HOME
# IMAGE_USER_UID
# IMAGE_USER_GID
# IMAGE_WORKSPACE_DIR
# IMAGE_CUSTOMISE_DIR

USER root

COPY dependencies/* ${DEPENDENCIES_DIR}/

SHELL ["/bin/bash", "-c"]

RUN export DEBIAN_FRONTEND=noninteractive \
    && install-apt-packages.sh ${DEPENDENCIES_DIR}/packages.txt

# Copy files to user home, including subdirectories
COPY --chown=${IMAGE_USER_UID} home/. ${IMAGE_USER_HOME}/

SHELL ["/bin/zsh", "-c"]

# Run as user
#   Install pipx depedancies
#   Install python dependencies
RUN su - ${IMAGE_USER_NAME} -c "\
    pip install --user --no-cache-dir -r ${DEPENDENCIES_DIR}/requirements.txt \
    && install-pipx-packages.sh ${DEPENDENCIES_DIR}/pipx.txt \
"


# Run container as user
USER ${IMAGE_USER_NAME}
# Keep container running
CMD ["tail", "-f", "/dev/null"]

