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

export KERNEL_TAG="master"

# run each build step
for DEBIAN_VERSION in "${DEBIAN_VERSIONS[@]}"; do
  export DEBIAN_VERSION
  . ./build-debs.sh
done
