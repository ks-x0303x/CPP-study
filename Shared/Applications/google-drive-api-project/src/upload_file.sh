#!/bin/bash

# Get the absolute directory of the current script
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

function show_help() {
    echo "Usage: $0 <file_path> <target_directory>"
    echo
    echo "Upload a file to Google Drive."
    echo
    echo "Options:"
    echo "  <file_path>         Path to the file to upload."
    echo "  <target_directory>  Target directory on Google Drive where the file will be uploaded."
    echo "  -h, --help          Show this help message and exit."
    echo
    echo "Examples:"
    echo "  $0 /path/to/file.txt MyDriveFolder"
    echo "  $0 ./example.txt BackupFolder"
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
FILE_PATH=$1
TARGET_DIR=$2

# Check if the file exists
if [ ! -f "$FILE_PATH" ]; then
    echo "Error: File '$FILE_PATH' does not exist."
    exit 1
fi

CONFIG_DIR="/usr/local/config"
if [[ ! -d "$CONFIG_DIR" ]]; then
    CONFIG_DIR="$SCRIPT_DIR"
fi

if [[ ! -f "$CONFIG_DIR/token.json" ]]; then
    echo "Error: token.json が見つかりません: $CONFIG_DIR/token.json"
    echo "先に認証を通して token.json を生成してください:"
    echo "  $SCRIPT_DIR/auth_quickstart.sh"
    exit 2
fi

# Execute the Python script with the provided arguments
python3 "$SCRIPT_DIR/google_drive_driver.py" upload -f "$FILE_PATH" -t "$TARGET_DIR"