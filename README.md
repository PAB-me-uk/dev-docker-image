# dev-docker-image

## Access host vm

```
docker run -it --rm --privileged --pid=host alpine:edge nsenter -t 1 -m -u -n -i sh
```

## Locate volumes

```
ls /var/lib/docker/volumes/
```