#!/bin/bash
docker run -it --rm --privileged --pid=host alpine:edge nsenter -t 1 -m -u -n -i bin/bash