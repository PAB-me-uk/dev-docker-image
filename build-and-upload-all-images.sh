#!/bin/bash
set -e

PARENT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$PARENT_PATH"

./build-and-upload-image.sh 3.6
./build-and-upload-image.sh 3.7
./build-and-upload-image.sh 3.8
./build-and-upload-image.sh 3.9
./build-and-upload-image.sh 3.10
