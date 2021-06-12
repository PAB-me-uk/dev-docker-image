#!/bin/bash
set -e

install_extensions_from_file () {
  file=$1
  if [[ -f $file ]]; then
    which code > /dev/null
    if [[ $? -eq 0 ]]; then
      echo "Installing extensions from file $file"
      while IFS="" read -r line || [ -n "$line" ]
      do
        if [[ ! -z "$line" ]] && ! [[ "$line" =~ "^ *#.*$" ]]; then
            code --install-extension $line
        fi
      done < $file
      sudo rm $file
    fi
  fi
}

install_extensions_from_file /tmp/dependencies/extensions.txt
install_extensions_from_file /tmp/custom-dependencies/extensions.txt