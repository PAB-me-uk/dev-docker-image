#%%
import docker

from typing import Union
from functools import lru_cache

from mypy_extensions import TypedDict


DEV_CONTAINER_PREFIX = "pabuk/dev-python:"

Container = TypedDict("Container", {"name": str, "python_version": str, "digests": list[str]})


@lru_cache(maxsize=1)
def get_docker_client():
    return docker.from_env()


def container_python_version(container) -> str:
    if container.attrs.get("Config", {}).get("Image", "").startswith(DEV_CONTAINER_PREFIX):
        image = container.attrs["Config"]["Image"]
        assert isinstance(image, str)
        return image.split(":")[1]
    return ""


def check_if_container_needs_upgrade(container: Container) -> bool:
    python_version = container["python_version"]
    image_name = DEV_CONTAINER_PREFIX + python_version
    registry_digest = get_registry_image_digest(image_name=image_name)
    if not registry_digest:
        raise SystemError(f"Could not find image is registry with name {image_name}")
    print(registry_digest)
    print(container["digests"])
    for digest in container["digests"]:
        if digest.endswith(registry_digest):
            return False
    return True


# Valid mount types - 'bind', 'volume', 'tmpfs', 'npipe'
@lru_cache(maxsize=1)  # type : ignore
def get_dev_containers() -> dict[str, Container]:
    return {
        # container.attrs.get("Config", {}).get("Image", "")
        container.name: {
            "name": container.name,
            "python_version": container_python_version(container=container),
            # container.attrs["Mounts"],
            # [mount for mount in container.attrs["Mounts"] if mount["Type"] not in ["volume", "bind"]],
            "digests": container.image.attrs.get("RepoDigests", []),
        }
        # (c.name, c.image, c.status, c.attrs["Config"]["Image"], c.attrs["Volumes"], [c.attrs["Mounts"]])
        for container in get_docker_client().containers.list(all=True)
        if container_python_version(container=container)
    }


def get_registry_image_digest(image_name) -> str:
    return (
        get_docker_client()
        .images.get_registry_data(image_name)
        .attrs.get("Descriptor", {})
        .get("digest", "")
    )


check_if_container_needs_upgrade(container=get_dev_containers()["dev_container"])
