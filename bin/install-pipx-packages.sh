#!/bin/bash
set -e
set -o pipefail

file=$1
if [[ ! -f $file ]]; then
  echo "File not found: '$file'"
  exit 1
fi

grep -v "^ *#" ${file} | xargs -I {} -n1 pipx install --python /usr/local/bin/python --pip-args='--no-cache-dir' {}
