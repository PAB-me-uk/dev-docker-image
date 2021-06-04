# dev-container

## Windows Prequisites

[Window Subsystem For Linux 2.0](https://docs.microsoft.com/en-us/windows/wsl/install-win10)

[Docker Desktop](https://docs.docker.com/docker-for-windows/wsl/)

Follow configuration instructions on links above

Ensure your docker desktop is not the deafult wsl OS use `wsl --list ` and `wsl --set-default OS-NAME-HERE` to choose the OS you installed from the microsoft store

At a command promt run `whl` to switch to your WLS OS

If you dont already have your ssh keys in ~/.ssh copy using commands below

cp -Rv /mnt/c/Users/YOUR_WINDOWS_USERNAME/.ssh/ ~/.ssh/
chmod 700 ~/.ssh
chmod 600 ~/.ssh/*

Same for AWS config

cp -Rv /mnt/c/Users/YOUR_WINDOWS_USERNAME/.aws/ ~/.aws/
chmod 700 ~/.aws
chmod 700 ~/.aws/*

Alternatively you can alter `create-and-run-container.sh` to mount `/mnt/c/Users/YOUR_WINDOWS_USERNAME/.ssh/` and `/mnt/c/Users/YOUR_WINDOWS_USERNAME/.aws/` directly

## Mac Prequisites

[Docker Desktop](https://docs.docker.com/docker-for-mac/install/)

Follow configuration instructions on links above

## Checkout repo

***If using windows this must be done in your main WSL OS***

```bash
eval $(ssh-agent)
ssh-add ~/.ssh/YOUR_SSH_KEYNAME
git clone REPO_SSH_URL
cd XXX
```

## Creating a new container

```bash
./build-create-and-run.sh my-container my-volume 3.8
```

Change my-x to desired names, 3.8 is desired Python version

## Connect to container

```bash
docker exec -it test-container zsh
```

Or use VSCode Docker and Remote Container Extensions to attach VSCode directly into container

## Stop Container

```
docker stop test-container
```

## Start Container

```
docker start test-container
```

## Notes

Volume is mounted as `/workspace` files within this directory will be persisted unless you delete the volume

Other paths within container will be lost if the container is removed or recreated.
