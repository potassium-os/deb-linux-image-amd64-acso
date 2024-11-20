#!/bin/false
# shellcheck shell=bash

# debug mode = set -x = loud
DEBUG="${DEBUG:-false}"
if $DEBUG; then
  set -exu
else
  set -eu
fi

export DEBUG

if ! (return 0 2>/dev/null)
then
  echo "This file is meant to be dotsourced, not executed!"
  exit 1
fi

BUILD_SCRIPT=$(cat << EOS

# debug mode = set -x = loud
DEBUG="\${DEBUG:-false}"
if \$DEBUG; then
  set -exu
else
  set -eu
fi

# Setup variables
export BUILD_DATE="${BUILD_DATE}"
export BUILD_ID="${BUILD_ID}"
export DEBEMAIL="${DEBEMAIL}"
export DEBFULLNAME="${DEBFULLNAME}"
export KBUILD_BUILD_VERSION="${KBUILD_BUILD_VERSION}"
export KDEB_PKGVERSION="${KDEB_PKGVERSION}"
export KERNEL_TAG="${KERNEL_TAG}"
export LOCALVERSION="${LOCALVERSION}"
export TOP_DIR="/opt/potassium"


BUILD_DIR="\${TOP_DIR}/build/\${BUILD_ID}/\${DEBIAN_VERSION}/\${KERNEL_TAG}"
export BUILD_DIR
OUTPUT_DIR="\${TOP_DIR}/output/\${BUILD_ID}/\${DEBIAN_VERSION}/\${KERNEL_TAG}"
export OUTPUT_DIR

export DEBIAN_FRONTEND="noninteractive"

# Setup build directories, ensure we can access them
cd "\${TOP_DIR}" || exit 1

mkdir -p "\${OUTPUT_DIR}"

mkdir -p "\${BUILD_DIR}"
cd "\${BUILD_DIR}" || exit 1

# Clone kernel sources
git clone \
  --depth=1 \
  --branch "\${KERNEL_TAG}" \
  https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git \
  "\${BUILD_DIR}/" || exit 5

cd "\${BUILD_DIR}/" || exit 1

KERNEL_COMMIT_SHORTHASH="\$(git log -1 --pretty=format:%h)"

if [[ "\${KERNEL_TAG}" == "master" ]]; then
  VERSION_DISPLAY_TEXT="commit \${KERNEL_COMMIT_SHORTHASH}"
else
  VERSION_DISPLAY_TEXT="tag \$(git describe --exact-match --tags HEAD)"
fi

KERNEL_MAJOR="\$(sed -nE 's/^VERSION = ([0-9]+)$/\1/p' Makefile)"
KERNEL_PATCHLEVEL="\$(sed -nE 's/^PATCHLEVEL = ([0-9]+)$/\1/p' Makefile)"
KERNEL_SUBLEVEL="\$(sed -nE 's/^SUBLEVEL = ([0-9]+)$/\1/p' Makefile)"
KERNEL_EXTRAVERSION="\$(sed -nE 's/^EXTRAVERSION = ([0-9]+)$/\1/p' Makefile)"

KERNEL_VERSION="\${KERNEL_MAJOR}.\${KERNEL_PATCHLEVEL}.\${KERNEL_SUBLEVEL}\${KERNEL_EXTRAVERSION}"

export KERNEL_COMMIT_SHORTHASH

export KERNEL_VERSION

export KERNEL_MAJOR
export KERNEL_PATCHLEVEL
export KERNEL_SUBLEVEL
export KERNEL_EXTRAVERSION

export VERSION_DISPLAY_TEXT

# Apply most specific patches available
for set in "\${TOP_DIR}"/patch/*; do
  if [ -d "\${set}/v\${KERNEL_MAJOR}.\${KERNEL_PATCHLEVEL}.\${KERNEL_SUBLEVEL}" ]; then
    for patch in "\${set}/v\${KERNEL_MAJOR}.\${KERNEL_PATCHLEVEL}.\${KERNEL_SUBLEVEL}"/*.patch; do
    	echo "Applying \${patch}"
    	patch -p1 --forward -i \${patch}
    done
  elif [ -d "\${set}/v\${KERNEL_MAJOR}.\${KERNEL_PATCHLEVEL}.z" ]; then
    for patch in "\${set}/v\${KERNEL_MAJOR}.\${KERNEL_PATCHLEVEL}.z"/*.patch; do
    	echo "Applying \${patch}"
    	patch -p1 --forward -i \${patch}
    done
  elif [ -d "\${set}/v\${KERNEL_MAJOR}.y.z" ]; then
    for patch in "\${set}/v\${KERNEL_MAJOR}.y.z"/*.patch; do
    	echo "Applying \${patch}"
    	patch -p1 --forward -i \${patch}
    done
  else
    for patch in "\${set}"/*.patch; do
    	echo "Applying \${patch}"
    	patch -p1 --forward -i \${patch}
    done
  fi
done

# sed -i 's/^CONFIG_SYSTEM_TRUSTED_KEYS.*/CONFIG_SYSTEM_TRUSTED_KEYS=""/' .config
# sed -i 's/^CONFIG_SYSTEM_REVOCATION_KEYS.*/CONFIG_SYSTEM_REVOCATION_KEYS=""/' .config

# mkdir the changelog directory
mkdir -p "\${BUILD_DIR}/debian"

# Create the changelog
dch --create --package "linux-upstream" --newversion "\${KERNEL_VERSION}-\${BUILD_ID}" "linux-image-amd64 \${KERNEL_VERSION} \${VERSION_DISPLAY_TEXT} with ACS Override Patch for Debian" || exit 1

# Flag it as a backport release
dch --bpo "CI Build \${BUILD_ID} on \${BUILD_DATE}" || exit 1

# Copy in kconfig
if [ -f "\${TOP_DIR}/kconfig/v\${KERNEL_MAJOR}.\${KERNEL_PATCHLEVEL}.\${KERNEL_SUBLEVEL}.config" ]; then
  cp "\${TOP_DIR}/kconfig/v\${KERNEL_MAJOR}.\${KERNEL_PATCHLEVEL}.\${KERNEL_SUBLEVEL}.config" .config
elif [ -f "\${TOP_DIR}/kconfig/v\${KERNEL_MAJOR}.\${KERNEL_PATCHLEVEL}.z.config" ]; then
  cp "\${TOP_DIR}/kconfig/v\${KERNEL_MAJOR}.\${KERNEL_PATCHLEVEL}.z.config" .config
elif [ -f "\${TOP_DIR}/kconfig/v\${KERNEL_MAJOR}.y.z.config" ]; then
  cp "\${TOP_DIR}/kconfig/v\${KERNEL_MAJOR}.y.z.config" .config
fi

# Do a olddefconfig just to be safe
make olddefconfig

# Make the toast
make VERBOSE=1 -j "$(nproc)" || exit 1

# Make debs
make VERBOSE=1 -j "$(nproc)" bindeb-pkg || exit 1

# Make the output dir
mkdir -p "\${OUTPUT_DIR}/"

cp "\${BUILD_DIR}/debian/changelog" "\${OUTPUT_DIR}/"
mv "\${BUILD_DIR}"/../*.deb "\${OUTPUT_DIR}/"

EOS
)

export BUILD_SCRIPT
