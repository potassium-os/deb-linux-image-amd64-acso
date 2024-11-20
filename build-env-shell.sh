#!/bin/bash

# debug mode = set -x = loud
DEBUG="${DEBUG:-false}"
if $DEBUG; then
  set -exu
else
  set -eu
fi

# where this .sh file lives
DIRNAME=$(dirname "$0")
SCRIPT_DIR=$(cd "$DIRNAME" || exit 1; pwd)
cd "$SCRIPT_DIR" || exit 1

DEFAULT_TOP_DIR="${SCRIPT_DIR}"
TOP_DIR="${TOP_DIR:-$DEFAULT_TOP_DIR}"

CONTAINER_TAG="latest-trixie"

CONTAINER_IMAGE="ghcr.io/potassium-os/deb-linux-image-amd64-acso"

podman run \
  --rm \
  -it \
  -v "${TOP_DIR}:/opt/potassium:rw" \
  "${CONTAINER_IMAGE}:${CONTAINER_TAG}" \
  /bin/bash --login
