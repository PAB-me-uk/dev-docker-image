#!/bin/bash
set -e

PARENT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$PARENT_PATH"

# ./build-image.sh 3.6
./build-image.sh 3.7
./build-image.sh 3.8
./build-image.sh 3.9
./build-image.sh 3.10
./build-image.sh 3.11
