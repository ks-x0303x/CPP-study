#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_DEFAULT="ubuntu-env:latest"
IMAGE_FALLBACK="ksx0303x/ubuntu-env:latest"
IMAGE="${IMAGE_DEFAULT}"

function show_help() {
    echo "Usage: $0"
    echo
    echo "Run a Docker container from a pulled image (no build)."
    echo
    echo "Notes:"
    echo "  - If the image does not exist locally, run ./pull_docker.sh first."
    echo "  - Preferred image: ${IMAGE_DEFAULT}"
    echo "  - Fallback image:  ${IMAGE_FALLBACK}"
    echo
    echo "Options:"
    echo "  -h, --help    Show this help message and exit."
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -* )
            echo "Unknown option: $1" >&2
            echo "Run with --help for usage." >&2
            exit 2
            ;;
        *)
            echo "Unexpected argument: $1" >&2
            echo "Run with --help for usage." >&2
            exit 2
            ;;
    esac
done

# Colima がある環境では起動状態を確認 (主に macOS)
if command -v colima >/dev/null 2>&1; then
    if ! colima status 2>&1 | grep -qi "running"; then
        echo "Colima is not running. Starting Colima..."
        colima start
    fi
fi

if ! docker image inspect "${IMAGE}" >/dev/null 2>&1; then
    if docker image inspect "${IMAGE_FALLBACK}" >/dev/null 2>&1; then
        IMAGE="${IMAGE_FALLBACK}"
    else
        echo "Error: Docker image not found locally: ${IMAGE_DEFAULT}" >&2
        echo "Also not found: ${IMAGE_FALLBACK}" >&2
        echo "Run: ./pull_docker.sh" >&2
        exit 1
    fi
fi

ENGINE_ARCH="$(docker info --format '{{.Architecture}}' 2>/dev/null || true)"
IMAGE_PLATFORM="$(docker image inspect "${IMAGE}" --format '{{.Os}}/{{.Architecture}}' 2>/dev/null || true)"
echo "Using image: ${IMAGE}" >&2
if [[ -n "${ENGINE_ARCH}" ]]; then
    echo "Docker Engine arch: ${ENGINE_ARCH}" >&2
fi
if [[ -n "${IMAGE_PLATFORM}" ]]; then
    echo "Image platform: ${IMAGE_PLATFORM}" >&2
fi

platform_args=()
if [[ -n "${IMAGE_PLATFORM}" ]]; then
	platform_args+=(--platform "${IMAGE_PLATFORM}")
fi

run_args=(
    "${platform_args[@]}"
    --rm
    -it
    -p 8080:8080
    -p 10000:10000
    -v "${SCRIPT_DIR}/Shared:/home/ubuntu/Shared"
    -v "${SCRIPT_DIR}/config:/usr/local/config"
    --cap-add SYS_PTRACE
    "${IMAGE}"
    bash
)

docker run "${run_args[@]}"
