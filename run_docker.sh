#!/bin/bash

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

# Check if help is requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Colima の状態を確認
STATUS=$(colima status | grep -i "status" | awk '{print $2}')

# 状態が "running" でない場合に Colima を起動
if [ "$STATUS" != "running" ]; then
    echo "Colima is not running. Starting Colima..."
    colima start
fi

# 引数で docker-compose ファイルを指定（デフォルトは docker-compose.yml）
COMPOSE_FILE=${1:-docker-compose.yml}

# 指定された docker-compose ファイルが存在するか確認
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "Error: Specified compose file '$COMPOSE_FILE' does not exist."
    exit 1
fi

# Docker Compose を起動
docker-compose -f "$COMPOSE_FILE" up -d
docker exec -it cpp-study-ubuntu-env-1 /bin/bash
