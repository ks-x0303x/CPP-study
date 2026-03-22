#!/usr/bin/env bash

set -euo pipefail

REPO="ksx0303x/ubuntu-env"

show_help() {
    cat << 'EOF'
Usage:
    ./push_docker.sh [TAG]

Examples:
  # Multi-arch push (manifest list)
    ./push_docker.sh
    ./push_docker.sh 1.0

Options:
    --platforms <list>     Platforms list (default: linux/amd64,linux/arm64)
  --builder <name>       Buildx builder name (default: cpp-study-builder)
    --install-binfmt       Install binfmt/QEMU handlers (needs privileged Docker)
  -h, --help             Show help

Notes:
  - Requires: docker buildx
  - Requires: docker login (Docker Hub)
    - This script builds and pushes a multi-arch image (manifest list).
    - Push requires permission to the Docker Hub repo: ksx0303x/ubuntu-env.
        - Note: buildx with --push does NOT leave a tagged image in `docker images`.
            (To see it locally, `docker pull ksx0303x/ubuntu-env:<TAG>` or use ./build_docker.sh.)
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TAG="latest"
PLATFORMS="linux/amd64,linux/arm64"
BUILDER="cpp-study-builder"
INSTALL_BINFMT="false"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        --platforms)
            PLATFORMS="$2"; shift 2
            ;;
        --builder)
            BUILDER="$2"; shift 2
            ;;
        --install-binfmt)
            INSTALL_BINFMT="true"; shift
            ;;
        -*)
            echo "Unknown option: $1" >&2
            echo "Run with --help for usage." >&2
            exit 2
            ;;
        *)
            TAG="$1"; shift
            ;;
    esac
done

if ! docker buildx version >/dev/null 2>&1; then
    echo "Error: docker buildx is not available in this Docker installation." >&2
    exit 1
fi

echo "Pushing multi-arch image: ${REPO}:${TAG}" >&2
echo "  platforms: ${PLATFORMS}" >&2
echo "  builder:   ${BUILDER}" >&2

if [[ "${INSTALL_BINFMT}" == "true" ]]; then
    if ! docker run --privileged --rm tonistiigi/binfmt --install all >/dev/null; then
        cat >&2 <<EOF
Error: failed to install binfmt/QEMU handlers.

This step requires a privileged Docker daemon.

Try one of the following:
  - Re-run without --install-binfmt (if binfmt is already installed)
  - Enable privileged containers for your Docker environment
  - Run on a host Docker daemon (not a restricted Docker-in-Docker)
EOF
        exit 1
    fi
fi

if docker buildx inspect "${BUILDER}" >/dev/null 2>&1; then
    docker buildx use "${BUILDER}" >/dev/null
else
    docker buildx create --name "${BUILDER}" --use >/dev/null
fi

buildx_args=(
    -t "${REPO}:${TAG}"
    -f "${SCRIPT_DIR}/Dockerfile"
    --push
)

buildx_args+=(--platform "${PLATFORMS}")

docker buildx build "${buildx_args[@]}" "${SCRIPT_DIR}"

cat >&2 <<EOF
Done: pushed ${REPO}:${TAG}

Note:
    - buildx --push does not keep a local image tag.
    - Verify the remote manifest:
            docker buildx imagetools inspect ${REPO}:${TAG}
EOF
