# Development Container

## Windows Prerequisites

### Windows Subsystem for Linux

#### Install WSL

Install WSL 2.0 from the Microsoft Store **or** via **Windows Command Prompt** using the following command:

```
wsl --install
```

In a Windows command prompt run these commands:

```bash
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
wsl --update
wsl --set-default-version 2
wsl
```

#### Install Ubuntu

From the **WSL terminal** run these commands:

```bash
wsl --install Ubuntu-24.04
wsl --set-default Ubuntu-24.04
wsl --list
```

#### Configure WSL

From the **WSL terminal** run the following command:

```bash
sudo nano /etc/wsl.conf
```

Paste in the following settings, then press ctrl+o then ctrl+x to save and exit nano.

```
[boot]
systemd=true
command="echo nameserver 1.1.1.1 > /etc/resolv.conf && echo nameserver 1.0.0.1 >> /etc/resolv.conf"
[network]
generateResolvConf = false
```

#### Restart WSL

From a normal **Windows Command Prompt** run the following commands:

```
wsl --shutdown
wsl
```

### Docker Install

From the **WSL terminal** follow the instruction via the link below

[Install Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/)

From the **WSL terminal** run the following commands:

```
sudo usermod -aG docker $USER
exit
```

#### Restart WSL

From a normal **Windows Command Prompt** run the following commands:

```
wsl --shutdown
wsl
```

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
code --install-extension biomejs.biome
code --install-extension charliermarsh.ruff
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
  "remote.containers.gitCredentialHelperConfigLocation": "none"
}
```

## Bootstrap first ever image

From the **WSL terminal** run the following commands:

```
mkdir -p ~/.aws ~/.ssh ~/.zsh-extra
touch .gitconfig
docker run --rm -it --env HOST_USER_HOME=$HOME --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock pabuk/dev-python:3.12 /bin/zsh -c "/home/dev/.local/bin/create-dev-container initial-container initial-volume 3.12 .zsh-extra"
```

The initial container and any custom containers (see below) will make use of this HOST_USER_NAME variable to mount the key files folders from the correct location.

## Connect to container

```bash
docker exec -it initial-container zsh
```

Or use VSCode Docker and Remote Container Extensions to attach VSCode directly into container

![./images/vsc-open-container.png](./images/vsc-open-container.png)

## Creating further containers

Once you have a container made from the bootstrap process above you can simply create further containers from within any dev container as below

```bash
create-dev-container another-container another-volume 3.12 .zsh-extra
```

Note this does not have to be the same python version as the existing container itself

## Important!

Volume is mounted as `/workspace` files within this directory will be persisted unless you delete the volume, data outside of the workspace directory will be lost if the container is removed or recreated.

Python dependencies are copied across to the volume during first launch and are stored in the directory /workspace/.python/3.x any further packages you install will also be placed here and will be available to any containers with this volume mounted that share the same Python version.
Performance

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

Note: When producing a custom image you should use a container that is based on the very latest image available from DockerHub, if in doubt simply create a new dev container which will pull the latest image and use this during the customisation steps below.

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

| File                           | Usage                                                                                                                                                                                           |
| ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| /dependencies/packages.txt     | Add any additional APT packages here.                                                                                                                                                           |
| /dependencies/requirements.txt | Add any additional Python PIP packages here.                                                                                                                                                    |
| /dependencies/pipx.txt         | Add any additional Python PIPX packages (stand alone Python utilities) here.                                                                                                                    |
| /dependencies/extensions.txt   | Add any additional Visual Studio Code extensions here, use command `code --list-extensions` from outside container to get correct name for an extension.                                        |
| /home (directory)              | Any files and folders placed in `/home` will be recursively copied to `/home/dev/` in the new custom container. You can use this to override any of the existing files from the original image. |
| /Dockerfile                    | Optionally add you own custom steps here as per [the documentation](https://docs.docker.com/engine/reference/builder/).                                                                         |

Run the command below to create a new custom dev container:

```bash
cd ~/customise
./create-custom-dev-container.sh custom-container-name volume-name 3.12
```

_Replace `3.12` above with desired Python version_

Note: You may wish to backup or version control your changes to the customisation files, as a minimum it is worth copying them to a volume e.g. `/workspace/`
