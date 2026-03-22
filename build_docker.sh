#!/usr/bin/env bash

set -euo pipefail

show_help() {
    cat << 'EOF'
Usage:
    ./build_docker.sh [TAG] [PLATFORM]

Examples:
  ./build_docker.sh
  ./build_docker.sh 1.0
  ./build_docker.sh 1.0 linux/amd64

Options:
    --image <name>         Image name (default: ubuntu-env)
  -h, --help             Show help

Notes:
    - This script only builds locally.
    - For pushing (single-arch / multi-arch), use ./push_docker.sh.
EOF
}

TAG="latest"
PLATFORM=""
IMAGE="ubuntu-env"

positional=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        --image)
            if [[ $# -lt 2 ]]; then
                echo "Error: --image requires a value." >&2
                show_help
                exit 2
            fi
            IMAGE="$2"; shift 2
            ;;
        --)
            shift
            while [[ $# -gt 0 ]]; do positional+=("$1"); shift; done
            ;;
        -*)
            echo "Unknown option: $1" >&2
            echo "Run with --help for usage." >&2
            exit 2
            ;;
        *)
            positional+=("$1"); shift
            ;;
    esac
done

if [[ ${#positional[@]} -ge 1 ]]; then
    TAG="${positional[0]}"
fi
if [[ ${#positional[@]} -ge 2 ]]; then
    PLATFORM="${positional[1]}"
fi

# Local build (classic docker build)
if [[ -n "${PLATFORM}" ]]; then
    docker build -t "${IMAGE}:${TAG}" --platform "${PLATFORM}" -f Dockerfile .
else
    docker build -t "${IMAGE}:${TAG}" -f Dockerfile .
fi