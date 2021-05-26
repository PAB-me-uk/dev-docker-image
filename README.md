# dev-container

# Create a volume (used to persist data)

```bash
./create-volume.sh test-volume
```

Argument is new volume name

# Build image

```bash
./build-image.sh 3.6
```

Argument is desired python version
Image will be called `dev-container-image:3.6`

# Create and run container

```
./create-and-run-container.sh test-container test-volume 3.6
```

Arguments are name for container, name of volume to mount, python version (used to select image)




