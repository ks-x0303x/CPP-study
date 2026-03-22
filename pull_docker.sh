#!/usr/bin/env bash

set -euo pipefail

REPO="ksx0303x/ubuntu-env"

show_help() {
	cat << 'EOF'
Usage:
	./pull_docker.sh [TAG] [--tag-as <local-image[:tag]>] [--no-retag]

Examples:
	./pull_docker.sh
	./pull_docker.sh 1.0

  # Pull and retag to match default compose image name
	./pull_docker.sh 1.0 --tag-as ubuntu-env:latest

	# Pull only (no local retag)
	./pull_docker.sh 1.0 --no-retag

Options:
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

if [[ ${#} -ge 1 && "$1" != -* ]]; then
	TAG="$1"
	shift
fi

while [[ $# -gt 0 ]]; do
	case "$1" in
		--tag-as)
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

docker pull "${IMAGE}"

if [[ "${NO_RETAG}" != "true" ]]; then
	docker tag "${IMAGE}" "${TAG_AS}"
fi