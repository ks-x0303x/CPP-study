#!/bin/bash

function show_help() {
    echo "Usage: $0 [TAG]"
    echo
    echo "Build a Docker image with the specified tag."
    echo "If no tag is provided, 'latest' will be used as the default."
    echo
    echo "Options:"
    echo "  TAG       Specify the tag for the Docker image (e.g., 1.0, 0.02)."
    echo "  -h, --help  Show this help message and exit."
}

# Check if help is requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Check if a tag is provided as an argument
if [ -z "$1" ]; then
    TAG="latest"
else
    TAG="$1"
fi

# Build the Docker image with the specified or default tag
docker build -t ubuntu-env:$TAG --platform linux/arm64 -f Dockerfile .