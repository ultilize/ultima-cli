#!/bin/bash

# Include global variables
source "${BASE_DIR}/globals.sh"

# Function to handle the 'version' command
version_command() {
    echo -e "Running version Ultima CLI ${LIGHTBLUE}v${VERSION}${NC}"
}