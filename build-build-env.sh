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

BUILD_TIME="$(date +%s)"

DEFAULT_DEBIAN_VERSION="trixie"
export DEBIAN_VERSION="${DEBIAN_VERSION:-$DEFAULT_DEBIAN_VERSION}"

CONTAINER_IMAGE="ghcr.io/potassium-os/deb-linux-image-amd64-acso"

time buildah build --layers --tag "${CONTAINER_IMAGE}:${BUILD_TIME}-${DEBIAN_VERSION}" --tag "${CONTAINER_IMAGE}:latest-${DEBIAN_VERSION}" -f "build-env/Containerfile.${DEBIAN_VERSION}" "build-env/${DEBIAN_VERSION}"
