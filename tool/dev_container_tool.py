from enum import Enum
from typing import Optional
from InquirerPy import inquirer
from InquirerPy.base.control import Choice
from lib.docker_utils import get_dev_containers


class Mode(Enum):
    CREATE = "create"
    UPGRADE = "upgrade"


def main() -> None:
    mode = select_mode()
    container_name, existing_container = select_container_name(mode=mode)
    print(mode, container_name, existing_container)


def select_mode() -> Mode:
    return inquirer.select(
        message="Please choose option",
        choices=[
            Choice(Mode.CREATE, "Create a new dev container"),
            Choice(Mode.UPGRADE, "Upgrade an existing dev container"),
        ],
    ).execute()


def select_container_name(mode: Mode) -> tuple[str, Optional[object]]:
    if mode is Mode.CREATE:
        return (inquirer.text(message="Enter a name for the new container:").execute(), None)
    elif mode is Mode.UPGRADE:
        containers = get_dev_containers()
        container_name = inquirer.select(
            message="Please select a container to upgrade",
            choices=sorted(containers.keys()),
        ).execute()
        return (container_name, containers[container_name])
    else:
        raise ValueError(f"Unknown mode: {mode}")


# name = inquirer.text(message="What's your name:").execute()
# confirm = inquirer.confirm(message="Confirm?").execute()
if __name__ == "__main__":
    main()
