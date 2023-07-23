#!/bin/bash
set -e
set -o pipefail

file=$1
if [[ ! -f ${file} ]]; then
  echo "File not found: '${file}'"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends apt-utils

count=$(grep -cv '^\s*$\|^\s*\#' ${file}) || true
if [[ ${count} -ne 0 ]]; then
  grep -v '^\s*$\|^\s*\#' ${file} | xargs apt-get install -y
fi

# Clear cache.
apt-get clean
