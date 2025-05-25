#!/bin/bash
# This script launches gdbserver with the specified parameters.

# Function to display help
show_help() {
    echo "Usage: $0 <app_path>"
    echo "Options:"
    echo "  -h          Show this help message"
    echo "Example:"
    echo "  $0 /path/to/your/application"
}

# Check if the first argument is -h or missing
if [ "$1" == "-h" ]; then
    show_help
    exit 0
elif [ -z "$1" ]; then
    echo "Error: Missing application path."
    show_help
    exit 1
fi

# Get the application path from the first argument
app_path=$1

# Launch gdbserver
gdbserver :10000 "${app_path}"