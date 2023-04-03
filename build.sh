#!/bin/sh
export COMPOSE_DOCKER_CLI_BUILD=1
export DOCKER_BUILDKIT=1

if [[ -z $1 ]] ; then
  docker-compose build
  exit 0
else
  S6_OVERLAY_VERSION="$1"
  docker-compose build --build-arg S6_OVERLAY_VERSION=${S6_OVERLAY_VERSION}
  exit 0
fi