#!/bin/bash

# Include global variables
source "${BASE_DIR}/globals.sh"

#Include set directory function
source "${BASE_DIR}/util/set_directory.sh"

update_command() {
    set_directory "$directory"
    directory=$selected_directory

    echo -e "${LIGHTBLUE}Updating docker-compose.yml...${NC}"
    cd "$directory" || { echo -e "${RED}Directory $directory not found.${NC}"; exit 1; }

    if curl -o docker-compose.yml "$GIST_URL"; then
        echo -e "${GREEN}docker-compose.yml updated successfully.${NC}"
    else
        echo -e "${RED}Failed to update docker-compose.yml.${NC}"
        exit 1
    fi

    echo -e "${LIGHTBLUE}Restarting Docker services...${NC}"
    docker-compose down
    docker-compose up -d
    echo -e "${GREEN}Update completed and services restarted.${NC}"
}