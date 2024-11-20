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

DEFAULT_KERNEL_TAG="v6.10"
export KERNEL_TAG="${KERNEL_TAG:-$DEFAULT_KERNEL_TAG}"

DEFAULT_DEBIAN_VERSION="trixie"
export DEBIAN_VERSION="${DEBIAN_VERSION:-$DEFAULT_DEBIAN_VERSION}"

export DEBEMAIL="honk@goos.blog"
export DEBFULLNAME="thehonker"

DEFAULT_BUILD_ID="$(date +%s)"
BUILD_ID="${BUILD_ID:-$DEFAULT_BUILD_ID}"
export BUILD_ID

DEFAULT_BUILD_DATE="$(date -R)"
BUILD_DATE="${BUILD_DATE:-$DEFAULT_BUILD_DATE}"
export BUILD_DATE

export KBUILD_BUILD_VERSION="${BUILD_ID}"
export KDEB_PKGVERSION="${KERNEL_TAG}-${BUILD_ID}"

export LOCALVERSION="-potassium-acso-${BUILD_ID}"

export DEBIAN_FRONTEND="noninteractive"

export CONTAINER_TAG="latest-${DEBIAN_VERSION}"

export CONTAINER_IMAGE="ghcr.io/potassium-os/deb-linux-image-amd64-acso"

# Load the build script
. ./build.inc.sh

# Make the toast

podman run \
  --rm \
  -it \
  --userns keep-id:uid=1000,gid=1000 \
  -v "${SCRIPT_DIR}:/opt/potassium:rw" \
  -e "DEBIAN_VERSION=${DEBIAN_VERSION}" \
  -e "DEBUG=true" \
  "${CONTAINER_IMAGE}:${CONTAINER_TAG}" \
  /bin/bash -c "${BUILD_SCRIPT}"
