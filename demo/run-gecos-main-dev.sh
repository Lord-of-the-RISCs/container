#!/usr/bin/env bash
#
# Opens the persistent Gecos main development worktree in the image that
# provides its Java, Maven, and SpecHLS dependencies. The Git repository lives
# in a Docker volume, so branches and commits survive after this shell exits.

set -eu

image=${SPECHLS_IMAGE:-spechls-demo:gecos-main}
volume=${GECOS_DEV_VOLUME:-gecos-main-dev-src}

exec docker run --rm -it \
  -v "$volume:/workspace" \
  -w /workspace \
  --entrypoint bash \
  "$image"
