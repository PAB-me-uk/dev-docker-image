# Development Container

## Windows Prerequisites

[Window Subsystem For Linux 2.0](https://docs.microsoft.com/en-us/windows/wsl/install-win10)

[Docker Desktop](https://docs.docker.com/docker-for-windows/wsl/)

*Follow configuration instructions from links above*

Ensure your docker desktop is not the default WSL OS use `wsl --list ` and `wsl --set-default YOUR_OS_NAME_HERE` to choose the OS you installed from the microsoft store

## Mac Prerequisites

[Docker Desktop](https://docs.docker.com/docker-for-mac/install/)

*Follow configuration instructions from link above*

## Visual Studio Code

This is optional but recommend for Python Development

Install from [here]([Visual Studio code](https://code.visualstudio.com/))

Install extensions

The first two are required and the rest recommend for Python and Javascript development.

```bash
# Required
code --install-extension ms-azuretools.vscode-docker
code --install-extension ms-vscode-remote.remote-containers
# Recommended
code --install-extension ms-python.python
code --install-extension ms-python.vscode-pylance
code --install-extension ms-toolsai.jupyter
code --install-extension dbaeumer.vscode-eslint
code --install-extension esbenp.prettier-vscode
code --install-extension Orta.vscode-jest
code --install-extension kddejong.vscode-cfn-lint
code --install-extension eastman.vscode-cfn-nag
code --install-extension streetsidesoftware.code-spell-checker
code --install-extension ryu1kn.partial-diff
code --install-extension moshfeu.compare-folders
code --install-extension oderwat.indent-rainbow
```

Press ctrl+shift+p for command palette and choose "Preferences: Open Settings (JSON)" to edit settings, add the setting below


```json
{
  "remote.containers.gitCredentialHelperConfigLocation": "none",
}
```

## Bootstrap first ever image

### MacOs

```bash
docker run --rm -it --env HOST_USER_HOME=${HOME} --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock pabuk/dev-python:3.9 /bin/zsh -c "/home/dev/.local/bin/create-dev-container initial-container initial-volume 3.9"
```

### Windows

***This must be done in your main WSL OS (type `wsl` in command prompt)***

Identify you windows user id via `ls /mnt/Users/` and replace YOUR_WINDOWS_USERNAME below

```bash
docker run --rm -it --env HOST_USER_HOME=/mnt/c/Users/YOUR_WINDOWS_USERNAME --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock pabuk/dev-python:3.9 /bin/zsh -c "/home/dev/.local/bin/create-dev-container initial-container initial-volume 3.9"
```

## Connect to container

```bash
docker exec -it initial-container zsh
```

Or use VSCode Docker and Remote Container Extensions to attach VSCode directly into container

![./images/vsc-open-container.png](./images/vsc-open-container.png)

## Creating further containers

Once you have a container made from the bootstrap process above you can simply create further containers from within the dev container itself as below

```bash
create-dev-container another-container another-volume 3.9
```

## Other commands

### Stop Container

```
docker stop test-container
```

### Start Container

```
docker start test-container
```

## Notes

Volume is mounted as `/workspace` files within this directory will be persisted unless you delete the volume

Other paths within container will be lost if the container is removed or recreated.
