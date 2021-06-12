ARG IMAGE_PYTHON_VERSION=3.9
FROM pabuk/dev-python:${IMAGE_PYTHON_VERSION}
# DEPENDENCIES_DIR Must not be same as main image (/tmp/dependencies)as will clash
ARG DEPENDENCIES_DIR=/tmp/custom-dependencies

# Environmental variables available to use in this file from parent image
# IMAGE_USER_NAME
# IMAGE_GROUP_NAME
# IMAGE_USER_HOME
# IMAGE_USER_UID
# IMAGE_USER_GID
# IMAGE_WORKSPACE_DIR
# IMAGE_CUSTOMISE_DIR

COPY dependencies/* ${DEPENDENCIES_DIR}/

SHELL ["/bin/bash", "-c"]

RUN export DEBIAN_FRONTEND=noninteractive \
    && cd /tmp \
    && apt-get update\
    # Install packages
    && grep -v "^ *#" ${DEPENDENCIES_DIR}/packages.txt | xargs apt-get install -y \
    && rm ${DEPENDENCIES_DIR}/packages.txt \
    && apt-get clean

# Copy files to user home, including subdirectories
COPY --chown=${IMAGE_USER_UID} home/. ${IMAGE_USER_HOME}/

# Run as user
#   Install pipx depedancies
#   Install python dependencies
RUN su - ${IMAGE_USER_NAME} -c "printf \"zsh\\n\" >> ~/.bashrc \
    && grep -v \"^ *#\" ${DEPENDENCIES_DIR}/pipx.txt | xargs -I {} -n1 pipx install --python /usr/local/bin/python --pip-args='--no-cache-dir' {} \
    && sudo rm ${DEPENDENCIES_DIR}/pipx.txt \
    && pip install -r ${DEPENDENCIES_DIR}/requirements.txt --user --no-warn-script-location --no-cache-dir \
    && sudo rm ${DEPENDENCIES_DIR}/requirements.txt"

# Run container as user
USER ${IMAGE_USER_NAME}
# Keep container running
CMD ["tail", "-f", "/dev/null"]

