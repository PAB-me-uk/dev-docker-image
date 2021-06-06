# Development Container

## Windows Prerequisites

[Window Subsystem For Linux 2.0](https://docs.microsoft.com/en-us/windows/wsl/install-win10)

[Docker Desktop](https://docs.docker.com/docker-for-windows/wsl/)

*Follow configuration instructions from links above*

Ensure your docker desktop is not the default WSL OS use `wsl --list ` and `wsl --set-default YOUR_OS_NAME_HERE` to choose the OS you installed from the microsoft store

At a command prompt run `whl` to switch to your WLS OS

If you dont already have your ssh keys in ~/.ssh copy using commands below

```bash
cp -Rv /mnt/c/Users/YOUR_WINDOWS_USERNAME/.ssh/ ~/.ssh/
chmod 700 ~/.ssh
chmod 600 ~/.ssh/*
```

Same for AWS config

```bash
cp -Rv /mnt/c/Users/YOUR_WINDOWS_USERNAME/.aws/ ~/.aws/
chmod 700 ~/.aws
chmod 700 ~/.aws/*
```

Alternatively you can alter `create-and-run-container.sh` to mount `/mnt/c/Users/YOUR_WINDOWS_USERNAME/.ssh/` and `/mnt/c/Users/YOUR_WINDOWS_USERNAME/.aws/` directly

## Mac Prerequisites

[Docker Desktop](https://docs.docker.com/docker-for-mac/install/)

*Follow configuration instructions from link above*

## Visual Studio Code

This is optional but recommend for Python Development

Install from [here]([Visual Studio code](https://code.visualstudio.com/))

Install extensions

The first two are required and the rest recommend for Python and Javascript development.

```bash
code --install-extension ms-azuretools.vscode-docker
code --install-extension ms-vscode-remote.remote-containers

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

## Checkout repo

***If using windows this must be done in your main WSL OS***

```bash
eval $(ssh-agent)
ssh-add ~/.ssh/YOUR_SSH_KEYNAME
git clone git@github.com:KCOM-Enterprise/Development-Tools.git
cd Development-Tools/DevContainers
```

## Creating a new container

```bash
./build-create-and-run.sh my-container my-volume 3.8
```

*Change my-xxx above to desired names, 3.8 is desired Python version.*

*Note: you can mount the same volume to multiple containers*

## Connect to container

```bash
docker exec -it test-container zsh
```

Or use VSCode Docker and Remote Container Extensions to attach VSCode directly into container

![./images/vsc-open-container.png](./images/vsc-open-container.png)

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
