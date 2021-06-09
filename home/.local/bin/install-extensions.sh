#!/bin/bash

if [[ -f /tmp/dependencies/extensions.txt ]]; then
    which code > /dev/null
    if [[ $? -eq 0 ]]; then
      set -e
      while IFS="" read -r p || [ -n "$p" ]
      do
        if [[ ! -z "$p" ]]
          then
            code --install-extension $p
        fi
      done < /tmp/dependencies/extensions.txt
      sudo rm /tmp/dependencies/extensions.txt
  fi
fi
