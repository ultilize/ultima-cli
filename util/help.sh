#!/bin/bash

# Include global variables
source "${BASE_DIR}/globals.sh"

# Function to handle the 'help' command
help_command() {
    echo -e ""
    echo -e "Ultima CLI commands"
    echo -e "Official panel Ultima CLI helper"
    echo -e ""
    echo -e "Usage: ultima [command(s)]"
    echo -e ""
    echo -e "Available commands:"
    echo -e "${GREEN}$ ${LIGHTBLUE}install [directory]    ${NC}Set up a new Ultima project in the specified directory (default: 'ultima')"
    echo -e "${GREEN}$ ${LIGHTBLUE}update                 ${NC}Update the Docker compose file and restart services"
    echo -e "${GREEN}$ ${LIGHTBLUE}change database        ${NC}Change the database configuration"
    echo -e "${GREEN}$ ${LIGHTBLUE}change credentials     ${NC}Change the admin credentials"
    echo -e ""
    echo -e "Available props:"
    echo -e "${GREEN}$ ${LIGHTBLUE}ultima-cli -v (-ver, -version)    ${NC}Shows current version of the CLI"
    echo -e ""
}