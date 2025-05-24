#!/bin/bash

# filepath: download_file.sh

# Get the absolute directory of the current script
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# Display help message
function show_help() {
    echo "Usage: $0 <src_file_path_or_id> <output_path>"
    echo
    echo "Download a file from Google Drive."
    echo
    echo "Options:"
    echo "  <src_file_path_or_id>  Path or ID of the file to download from Google Drive."
    echo "  <output_path>          Path to save the downloaded file (can be a directory or a file path)."
    echo "  -h, --help             Show this help message and exit."
    echo
    echo "Examples:"
    echo "  $0 Test/hoge/huga/test.txt ./"
    echo "  $0 1a2b3c4d5e6f ./"
}

# Check if help is requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Error: Invalid number of arguments."
    echo "Use '$0 --help' for usage information."
    exit 1
fi

# Assign arguments to variables
SRC_FILE_PATH_OR_ID=$1
OUTPUT_PATH=$2

# Execute the Python script with the provided arguments
python3 "$SCRIPT_DIR/google_drive_driver.py" download -f "$SRC_FILE_PATH_OR_ID" -o "$OUTPUT_PATH"