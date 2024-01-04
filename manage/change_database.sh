#!/bin/bash

# Include global variables
source "${BASE_DIR}/globals.sh"

#Include set directory function
source "${BASE_DIR}/util/set_directory.sh"

change_database_command() {
    set_directory "$directory"
    directory=$selected_directory

    cd $directory

    echo -e "${LIGHTBLUE}Updating database configuration...${NC}"
    echo -e "${RED}Support is only for PostgreSQL databases for now!${NC}"
    read -p "Enter new database host: " new_db_host
    read -p "Enter new database port: " new_db_port
    read -p "Enter new database user: " new_db_user
    read -s -p "Enter new database password: " new_db_password
    echo ""
    read -p "Enter new database: " new_db_db

    sed -i "s/POSTGRES_HOST=.*/POSTGRES_HOST=$new_db_host/" .env
    sed -i "s/POSTGRES_PORT=.*/POSTGRES_PORT=$new_db_port/" .env
    sed -i "s/POSTGRES_USER=.*/POSTGRES_USER=$new_db_user/" .env
    sed -i "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$new_db_password/" .env
    sed -i "s/POSTGRES_DB=.*/POSTGRES_DB=$new_db_db/" .env

    echo -e "${GREEN}Database configuration updated.${NC}"
    docker-compose down
    docker-compose up -d
    echo -e "${GREEN}Services restarted with new database configuration.${NC}"
}