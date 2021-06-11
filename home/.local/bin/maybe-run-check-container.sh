#!/bin/bash

if [[ ! -f ~/.suppress_check_container ]]; then
    check-container
    echo "Container checks above will run once only, to rerun use command `check-container`"
    touch ~/.suppress_check_container
fi