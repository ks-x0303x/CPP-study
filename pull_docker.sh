#!/usr/bin/env bash

set -euo pipefail

REPO="ksx0303x/ubuntu-env"

show_help() {
	cat << 'EOF'
Usage:
	./pull_docker.sh [TAG] [--platform <platform>] [--tag-as <local-image[:tag]>] [--no-retag]

Examples:
	./pull_docker.sh
	./pull_docker.sh 1.0

  # Pull and retag to match default compose image name
	./pull_docker.sh 1.0 --tag-as ubuntu-env:latest

	# Pull only (no local retag)
	./pull_docker.sh 1.0 --no-retag

Options:
	--platform <platform> Optional. Force platform for docker pull (e.g., linux/amd64, linux/arm64).
	--tag-as <name>   Optional. Retag the pulled image locally (default: ubuntu-env:latest).
	--no-retag        Optional. Don't retag locally.
  -h, --help        Show help.
EOF
}

if [[ ${#} -ge 1 && ( "$1" == "-h" || "$1" == "--help" ) ]]; then
	show_help
	exit 0
fi

TAG="latest"
TAG_AS="ubuntu-env:latest"
NO_RETAG="false"
PLATFORM=""

if [[ ${#} -ge 1 && "$1" != -* ]]; then
	TAG="$1"
	shift
fi

while [[ $# -gt 0 ]]; do
	case "$1" in
		--platform)
			if [[ $# -lt 2 ]]; then
				echo "Error: --platform requires an argument." >&2
				echo "Run with --help for usage." >&2
				exit 2
			fi
			PLATFORM="$2"; shift 2
			;;
		--tag-as)
			if [[ $# -lt 2 ]]; then
				echo "Error: --tag-as requires an argument." >&2
				echo "Run with --help for usage." >&2
				exit 2
			fi
			TAG_AS="$2"; shift 2
			;;
		--no-retag)
			NO_RETAG="true"; shift
			;;
		-h|--help)
			show_help
			exit 0
			;;
		*)
			echo "Unknown option: $1" >&2
			echo "Run with --help for usage." >&2
			exit 2
			;;
	esac
done

IMAGE="${REPO}:${TAG}"

# Decide platform automatically (based on Docker Engine architecture)
if [[ -z "${PLATFORM}" ]]; then
	ENGINE_ARCH=""
	if ENGINE_ARCH="$(docker info --format '{{.Architecture}}' 2>/dev/null)"; then
		case "${ENGINE_ARCH}" in
			aarch64|arm64)
				PLATFORM="linux/arm64"
				;;
			x86_64|amd64)
				PLATFORM="linux/amd64"
				;;
			*)
				PLATFORM=""
				;;
		esac
	fi
fi

pull_args=()
if [[ -n "${PLATFORM}" ]]; then
	pull_args+=(--platform "${PLATFORM}")
	echo "Pulling platform-specific image: ${IMAGE} (${PLATFORM})" >&2
else
	echo "Pulling image (platform auto): ${IMAGE}" >&2
fi

docker pull "${pull_args[@]}" "${IMAGE}"

if [[ "${NO_RETAG}" != "true" ]]; then
	docker tag "${IMAGE}" "${TAG_AS}"
fi