#!/bin/bash

# filepath: download_file.sh

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <src_file_path_or_id> <output_path>"
    exit 1
fi

# Assign arguments to variables
SRC_FILE_PATH=$1
OUTPUT_PATH=$2

# Check if the output directory exists (if it's a directory)
if [ -d "$OUTPUT_PATH" ]; then
    echo "Output path is a directory. The file will be saved inside the directory."
fi

# Execute the Python script with the provided arguments
python3 ~/Shared/Applications/google-drive-api-project/src/google_drive_driver.py download -f "$SRC_FILE_PATH" -o "$OUTPUT_PATH"