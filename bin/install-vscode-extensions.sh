#!/bin/bash
set -e

install_vscode_extensions () {
  file=$1
  if [[ -f $file ]]; then
    which code > /dev/null
    if [[ $? -eq 0 ]]; then
      echo "Installing extensions from file $file"
      grep -v "^ *#" $file | while IFS="" read -r line ; do
      if [[ ! -z "$line" ]] ; then # Not empty
        result=$(code --install-extension $line)
        fail=$(echo $result | grep -c "Failed Installing Extensions") || true
        echo $fail - $result
        if [[ $fail -ne 0 ]] ; then
          echo Failed
          exit 1
        fi
      fi
      done
      echo Succeeded
      sudo rm $file
    fi
  fi
}

install_vscode_extensions /var/dependencies/extensions.txt
install_vscode_extensions /var/custom-dependencies/extensions.txt

