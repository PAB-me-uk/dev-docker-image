#!/bin/bash
set -e
set -o pipefail

file=$1
if [[ ! -f $file ]]; then
  echo "File not found: '$file'"
  exit 1
fi

count=$(grep -cv '^\s*$\|^\s*\#' ${file}) || true
if [[ ${count} -ne 0 ]]; then
  grep -v '^\s*$\|^\s*\#' ${file} | xargs -I {} -n1 pipx install --python /usr/local/bin/python --pip-args='--no-cache-dir' {}
fi
