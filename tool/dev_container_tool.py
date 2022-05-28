#%%
import docker
from typing import Union

DEV_CONTAINER_PREFIX = "pabuk/dev-python:"

client = docker.from_env()
#%%
def container_python_version(container) -> Union[str, bool]:
    if container.attrs.get("Config", {}).get("Image", "").startswith(DEV_CONTAINER_PREFIX):
        image = container.attrs["Config"]["Image"]
        assert isinstance(image, str)
        return image.split(":")[1]
    return False


# Valid mount types - 'bind', 'volume', 'tmpfs', 'npipe'

#%%
[
    # container.attrs.get("Config", {}).get("Image", "")
    (
        container.name,
        container_python_version(container=container),
        # container.attrs["Mounts"],
        # [mount for mount in container.attrs["Mounts"] if mount["Type"] not in ["volume", "bind"]],
        container.image.attrs.get("RepoDigests", []),
    )
    # (c.name, c.image, c.status, c.attrs["Config"]["Image"], c.attrs["Volumes"], [c.attrs["Mounts"]])
    for container in client.containers.list()
    if container_python_version(container=container) == "3.6"
]


#%%

registry_data = client.images.get_registry_data("pabuk/dev-python:3.6")

#%%

registry_data.__dict__
#%%
