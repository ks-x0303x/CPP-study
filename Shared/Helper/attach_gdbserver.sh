#!/bin/bash
# This script attach gdbserver with the specified parameters.

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

# Get the application name from the first argument
app_name=$1

# Filter processes and retrieve the PID, excluding this script and grep itself
pid=$(ps aux | grep "$app_name" | grep -v "grep" | grep -v "$0" | awk '{print $2}')

# Check if a PID was found
if [ -z "$pid" ]; then
    echo "No process found for application: $app_name"
    exit 1
else
    echo "PID for application '$app_name': $pid"
fi

# Launch gdbserver
gdbserver --multi :10000