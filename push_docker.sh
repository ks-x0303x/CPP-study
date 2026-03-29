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
        --progress <mode>      Build progress output: auto|plain|tty (default: auto)
    --install-binfmt       Install binfmt/QEMU handlers (needs privileged Docker)
  -h, --help             Show help

Notes:
  - Requires: docker buildx
  - Requires: docker login (Docker Hub)
    - This script builds and pushes a multi-arch image (manifest list).
    - Push requires permission to the Docker Hub repo: ksx0303x/ubuntu-env.
        - If TAG looks like a version (e.g. 1.1), this script also tags/pushes the same image as :latest.
        - Note: buildx with --push does NOT leave a tagged image in `docker images`.
            (To see it locally, `docker pull ksx0303x/ubuntu-env:<TAG>` or use ./build_docker.sh.)
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TAG="latest"
PLATFORMS="linux/amd64,linux/arm64"
BUILDER="cpp-study-builder"
PROGRESS="auto"
INSTALL_BINFMT="false"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        --platforms)
            if [[ $# -lt 2 ]]; then
                echo "Error: --platforms requires an argument." >&2
                show_help
                exit 2
            fi
            PLATFORMS="$2"; shift 2
            ;;
        --builder)
            if [[ $# -lt 2 ]]; then
                echo "Error: --builder requires an argument." >&2
                show_help
                exit 2
            fi
            BUILDER="$2"; shift 2
            ;;
        --progress)
            if [[ $# -lt 2 ]]; then
                echo "Error: --progress requires an argument." >&2
                show_help
                exit 2
            fi
            PROGRESS="$2"; shift 2
            ;;
        --progress=*)
            PROGRESS="${1#*=}"; shift
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
TAG_LATEST="false"
if [[ "${TAG}" != "latest" ]]; then
    # Only move :latest when pushing a version-like tag.
    if [[ "${TAG}" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
        TAG_LATEST="true"
    fi
fi

if ! docker buildx version >/dev/null 2>&1; then
    echo "Error: docker buildx is not available in this Docker installation." >&2
    exit 1
fi

if [[ "${TAG_LATEST}" == "true" ]]; then
    echo "Pushing multi-arch image: ${REPO}:${TAG} (and tagging as ${REPO}:latest)" >&2
else
    echo "Pushing multi-arch image: ${REPO}:${TAG}" >&2
fi
echo "  platforms: ${PLATFORMS}" >&2
echo "  builder:   ${BUILDER}" >&2
echo "  progress:  ${PROGRESS}" >&2

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

if [[ "${TAG_LATEST}" == "true" ]]; then
    buildx_args+=( -t "${REPO}:latest" )
fi

buildx_args+=(--platform "${PLATFORMS}")
buildx_args+=(--progress "${PROGRESS}")

docker buildx build "${buildx_args[@]}" "${SCRIPT_DIR}"

cat >&2 <<EOF
Done: pushed ${REPO}:${TAG}
EOF

if [[ "${TAG_LATEST}" == "true" ]]; then
    echo "Also tagged/pushed: ${REPO}:latest" >&2
fi

cat >&2 <<EOF

Note:
    - buildx --push does not keep a local image tag.
    - Verify the remote manifest:
            docker buildx imagetools inspect ${REPO}:${TAG}
EOF
