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

Identify you windows user id via `ls /mnt/c/Users/` and replace YOUR_WINDOWS_USERNAME below

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

## Important!

Volume is mounted as `/workspace` files within this directory will be persisted unless you delete the volume

Other paths within container will be lost if the container is removed or recreated.

## Other commands

### Stop Container

```bash
docker stop test-container
```

### Start Container

```bash
docker start test-container
```

### Copy files to or from container

```bash
docker cp /wherever/this.txt container-name:/home/dev/

docker cp container-name:/home/dev/this.txt /wherever/
```

## Customisation

### Aliases

Create files containing your aliases (and any other zsh customisation) in `~/.zsh-extra` any files found will be picked up when you next open a terminal.

### Further customisation of image

You can create a customised version by following the steps below, this example uses Visual Studio Code, but this is not a requirement.

From within an existing dev container:

```bash
code ~/customise
```

This will open a new window to the same container pointing to the customisation files with the structure below:

```
/home/dev/customise
├── Dockerfile
├── create-custom-dev-container.sh
├── dependencies
│   ├── extensions.txt
│   ├── packages.txt
│   ├── pipx.txt
│   └── requirements.txt
└── home
```

Update files within the `/home/dev/customise` directory as below:

| File | Usage |
| ---- | ----  |
| /dependencies/packages.txt | Add any additional APT packages here. |
| /dependencies/requirements.txt | Add any additional Python PIP packages here. |
| /dependencies/pipx.txt | Add any additional Python PIPX packages (stand alone Python utilities) here. |
| /dependencies/extensions.txt | Add any additional Visual Studio Code extensions here, use command `code --list-extensions` from outside container to get correct name for an extension. |
| /home (directory) | Any files and folders placed in `/home` will be recursively copied to `/home/dev/` in the new custom container. You can use this to override any of the existing files from the original image. |
| /Dockerfile | Optionally add you own custom steps here as per [the documentation](https://docs.docker.com/engine/reference/builder/). |

Run the command below to create a new custom dev container:

```bash
cd ~/customise
./create-custom-dev-container.sh custom-container-name volume-name 3.9
```

*Replace `3.9` above with desired Python version*

Note: You may wish to backup or version control your changes to the customisation files, as a minimum it is worth copying them to a volume e.g. `/workspace/`
