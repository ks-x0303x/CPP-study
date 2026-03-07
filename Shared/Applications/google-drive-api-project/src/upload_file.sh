#!/bin/bash

# Get the absolute directory of the current script
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

function show_help() {
    echo "Usage: $0 <file_path...> <target_directory>"
    echo
    echo "Upload one or more files to Google Drive."
    echo
    echo "Options:"
    echo "  <file_path...>      One or more paths to the files to upload. (globs are OK)"
    echo "  <target_directory>  Target directory on Google Drive where the file will be uploaded."
    echo "  -h, --help          Show this help message and exit."
    echo
    echo "Examples:"
    echo "  $0 /path/to/file.txt MyDriveFolder"
    echo "  $0 ./example.txt BackupFolder"
    echo "  $0 ./test* ./        # upload to Drive root"
}

# Check if help is requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Check if the correct number of arguments is provided
if [ "$#" -lt 2 ]; then
    echo "Error: Invalid number of arguments."
    echo "Use '$0 --help' for usage information."
    exit 1
fi

# Assign arguments to variables
TARGET_DIR="${@: -1}"
FILE_PATHS=("${@:1:$#-1}")

# Normalize target for Drive root
if [[ "$TARGET_DIR" == "." || "$TARGET_DIR" == "./" ]]; then
    TARGET_DIR=""
fi

# Check if the file exists (except glob patterns; those are handled in python)
for FILE_PATH in "${FILE_PATHS[@]}"; do
    if [[ "$FILE_PATH" != *"*"* && "$FILE_PATH" != *"?"* && "$FILE_PATH" != *"["* ]]; then
        if [ ! -f "$FILE_PATH" ]; then
            echo "Error: File '$FILE_PATH' does not exist."
            exit 1
        fi
    fi
done

CONFIG_DIR="/usr/local/config"
if [[ ! -f "$CONFIG_DIR/token.json" ]]; then
    CONFIG_DIR="$SCRIPT_DIR"
fi

if [[ ! -f "$CONFIG_DIR/token.json" ]]; then
    echo "Error: token.json が見つかりません: $CONFIG_DIR/token.json"
    echo "先に認証を通して token.json を生成してください:"
    echo "  $SCRIPT_DIR/auth_quickstart.sh"
    exit 2
fi

# Execute the Python script with the provided arguments
for FILE_PATH in "${FILE_PATHS[@]}"; do
    python3 "$SCRIPT_DIR/google_drive_driver.py" upload -f "$FILE_PATH" -t "$TARGET_DIR"
done