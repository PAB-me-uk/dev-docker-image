# dev-container

## Build image (once per python version)

```bash
# Linux \ MacOS
./build-image.sh 3.6
# Windows
.\build-image.bat 3.6
```

Argument is desired python version
Image will be called `dev-container-image:3.6`

## Create a volume (used to persist data) (once per client)

```bash
# Linux \ MacOS
./create-volume.sh test-volume 
# Windows
.\create-volume.bat test-volume 
```

Argument is new volume name

## Create and run container (once per container)

```bash
# Linux \ MacOS
./create-and-run-container.sh test-container test-volume 3.6
# Windows
.\create-and-run-container.bat test-container test-volume 3.6
```

Arguments are name for container, name of volume to mount, python version (used to select image)

## Connect to container

```bash
docker exec -it test-container zsh
```

Or use VSCode Docker to attach VSCode

## Stop Container

```
docker stop test-container
```

## Start Container

```
docker start test-container
```

## Notes

Volume is mounted as `/workspace` files within this directory will be persisted

Other paths within container will be lost if the container is removed or recreated.

If using WSL 2.0 you should checkout this code and use within a WSL2.0 OS for best performance rather than using directly in windows. See https://docs.docker.com/docker-for-windows/wsl/ for more information
