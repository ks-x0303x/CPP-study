#!/bin/bash

set -euo pipefail

COMPOSE_FILE="docker-compose.yml"

function show_help() {
    echo "Usage: $0 [COMPOSE_FILE]"
    echo
    echo "Run a Docker container using the specified docker-compose file."
    echo "If no compose file is provided, 'docker-compose.yml' will be used as the default."
    echo
    echo "Options:"
    echo "  COMPOSE_FILE  Specify the docker-compose file to use (e.g., docker-compose.yml, docker-compose2.yml)."
    echo "  -h, --help    Show this help message and exit."
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            echo "Unknown option: $1" >&2
            echo "Run with --help for usage." >&2
            exit 2
            ;;
        *)
            COMPOSE_FILE="$1"; shift
            ;;
    esac
done

compose() {
    if docker compose version >/dev/null 2>&1; then
        docker compose "$@"
    else
        docker-compose "$@"
    fi
}

# Colima がある環境では起動状態を確認 (主に macOS)
if command -v colima >/dev/null 2>&1; then
    STATUS=$(colima status | grep -i "status" | awk '{print $2}' || true)
    if [ "${STATUS}" != "running" ]; then
        echo "Colima is not running. Starting Colima..."
        colima start
    fi
fi

# 指定された docker-compose ファイルが存在するか確認
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "Error: Specified compose file '$COMPOSE_FILE' does not exist."
    exit 1
fi

# Docker Compose を起動
compose -f "$COMPOSE_FILE" run --rm --service-ports ubuntu-env bash
# docker exec -it cpp-study-ubuntu-env-1 /bin/bash
# docker compose run --rm --service-ports ubuntu-env bash
