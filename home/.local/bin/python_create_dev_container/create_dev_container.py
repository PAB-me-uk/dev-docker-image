#!/usr/bin/env python
import docker
import argparse


def main():
    args=get_arguments()
    print(args)

    docker_client = docker.from_env()
    delete_existing_container(
        docker_client=docker_client,
        args=args
    )


def delete_existing_container(docker_client, args):
    container_names = [
        container.name
        for container in docker_client.containers.list(all=True)
    ]

    if args.container_name in container_names:
        # @todo prompt?
        print(f'Deleting existing container with name: {args.container_name}')


def get_arguments():
    parser = argparse.ArgumentParser(description='Create a dev container')
    parser.add_argument('--container-name', required=True)
    parser.add_argument('--volume-name', required=True)
    parser.add_argument('--python-version', required=True, choices=[
        "3.6",
        "3.7",
        "3.8",
        "3.9",
        "3.10"
    ])
    return parser.parse_args()

if __name__ == "__main__":
    main()
