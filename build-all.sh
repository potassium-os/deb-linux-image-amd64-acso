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

BUILD_ID="$(date +%s)"
export BUILD_ID

BUILD_DATE="$(date -R)"
export BUILD_DATE

# build steps to run (in order)
DEBIAN_VERSIONS=("trixie" "bookworm" "bullseye")
# KERNEL_TAGS=("master" "v6.12" "v6.11.9" "v6.6.62" "v6.1.118" "v5.15.173" "v5.10.230" "v5.4.286" "v4.19.324")

KERNEL_TAGS=("master" "v6.12")

CONTAINER_IMAGE="ghcr.io/potassium-os/deb-linux-image-amd64-acso"

# run each build step
for DEBIAN_VERSION in "${DEBIAN_VERSIONS[@]}"; do
  echo "====================================="
  echo "Building for Debian ${DEBIAN_VERSION}"
  echo "====================================="

  export DEBIAN_VERSION
  time buildah build --layers --tag "${CONTAINER_IMAGE}:${BUILD_ID}-${DEBIAN_VERSION}" --tag "${CONTAINER_IMAGE}:latest-${DEBIAN_VERSION}" -f "build-env/Containerfile.${DEBIAN_VERSION}" "build-env/${DEBIAN_VERSION}"

  for KERNEL_TAG in "${KERNEL_TAGS[@]}"; do
    echo "============================="
    echo "Building kernel ${KERNEL_TAG}"
    echo "============================="

    export KERNEL_TAG
    . ./build-debs.sh
  done
done
