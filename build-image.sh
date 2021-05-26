set -e
if [[ $# -ne 1 ]]; then
    echo "$0: A single argument for python version number is required (e.g. `3.8`)."
    exit 4
fi

docker build . -t dev-container-image-python:$1 --build-arg PYTHON_VERSION=$1
