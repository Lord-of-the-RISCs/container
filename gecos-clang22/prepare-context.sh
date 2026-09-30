#!/usr/bin/env bash
#
# Create the minimal Docker build context for hls-mlir-demo:spechls. Every
# source directory is exported from HEAD, rather than copied from a worktree,
# so local modifications and generated files cannot enter the image.

set -euo pipefail

if [[ $# -ne 1 ]]; then
  printf 'Usage: %s <LOTR repository root>\n' "$0" >&2
  exit 2
fi

repository_root=$(realpath "$1")
dockerfile_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
context_dir=$(mktemp -d "${TMPDIR:-/tmp}/hls-mlir-demo-context.XXXXXX")

cleanup() {
  rm -rf "$context_dir"
}
trap cleanup EXIT

# Export one Git worktree at its checked-out commit, preserving no uncommitted
# content. The target directory is created before tar extracts the archive.
export_head() {
  local source=$1
  local destination=$2

  mkdir -p "$destination"
  git -C "$source" archive --format=tar HEAD | tar -xf - -C "$destination"
}

# Add initialized submodules recursively. Uninitialized optional submodules are
# deliberately omitted: the Java package build does not require their sources.
export_initialized_submodules() {
  local source=$1
  local destination=$2
  local submodule

  while IFS= read -r submodule; do
    [[ -n "$submodule" ]] || continue
    export_head "$source/$submodule" "$destination/$submodule"
  done < <(git -C "$source" submodule foreach --quiet --recursive 'printf "%s\n" "$sm_path"')
}

export_head "$repository_root/spechls-circt" "$context_dir/sources/spechls-circt"

# CIRCT is a SpecHLS submodule and LLVM is its submodule. Export each directly
# to make their role in the image layout explicit and independently auditable.
export_head "$repository_root/spechls-circt/thirdparties/circt" "$context_dir/sources/circt"
export_head "$repository_root/spechls-circt/thirdparties/circt/llvm" "$context_dir/sources/llvm"
export_head "$repository_root/gecos-hls" "$context_dir/sources/gecos-hls"
export_initialized_submodules "$repository_root/gecos-hls" "$context_dir/sources/gecos-hls"
export_head "$repository_root/setup/yosys" "$context_dir/sources/yosys"
export_initialized_submodules "$repository_root/setup/yosys" "$context_dir/sources/yosys"

{
  printf 'spechls-circt=%s\n' "$(git -C "$repository_root/spechls-circt" rev-parse HEAD)"
  printf 'circt=%s\n' "$(git -C "$repository_root/spechls-circt/thirdparties/circt" rev-parse HEAD)"
  printf 'llvm=%s\n' "$(git -C "$repository_root/spechls-circt/thirdparties/circt/llvm" rev-parse HEAD)"
  printf 'gecos-hls=%s\n' "$(git -C "$repository_root/gecos-hls" rev-parse HEAD)"
  printf 'yosys=%s\n' "$(git -C "$repository_root/setup/yosys" rev-parse HEAD)"
} > "$context_dir/revisions.txt"

docker build \
  --build-arg BUILD_JOBS=32 \
  --tag hls-mlir-demo:spechls \
  --file "$dockerfile_dir/Dockerfile" \
  "$context_dir"
