#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <file_path> <target_directory>"
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

# Execute the Python script with the provided arguments
python3 .src/google_drive_driver.py upload -f "$FILE_PATH" -t "$TARGET_DIR"