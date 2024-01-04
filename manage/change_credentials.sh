#!/bin/bash

# Include global variables
source "${BASE_DIR}/globals.sh"

#Include set directory function
source "${BASE_DIR}/util/set_directory.sh"

change_credentials_command() {
    set_directory "$directory"
    directory=$selected_directory

    cd $directory

    echo -e "${LIGHTBLUE}Updating admin credentials...${NC}"
    read -p "Enter new admin email: " new_admin_email
    read -s -p "Enter new admin password: " new_admin_password
    echo ""

    sed -i "s/PGADMIN_DEFAULT_EMAIL=.*/PGADMIN_DEFAULT_EMAIL=$new_admin_email/" .env
    sed -i "s/PGADMIN_DEFAULT_PASSWORD=.*/PGADMIN_DEFAULT_PASSWORD=$new_admin_password/" .env

    echo -e "${GREEN}Admin credentials updated.${NC}"
    docker-compose down
    docker-compose up -d
    echo -e "${GREEN}Services restarted with new credentials.${NC}"
}