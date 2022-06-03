#!/bin/sh
export COMPOSE_DOCKER_CLI_BUILD=1
export DOCKER_BUILDKIT=1

if [[ $# -ne 1 ]] ; then
  echo "Usage: $(basename $0) <CPU_ARCH>"
  exit 1
else
  CPU_ARCH="$1"
  docker-compose build --build-arg s6_arch=${CPU_ARCH}
  exit 0
fi