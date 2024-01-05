#!/bin/bash

# Include global variables
source "${BASE_DIR}/globals.sh"

# Function to handle the 'install' command
install_command() {
    local directory=${2:-/home/ultima}

    echo -e "${LIGHTBLUE}Starting Ultima installation...${NC}"
    sleep 1
    install_docker

    echo -e "${LIGHTBLUE}Setting up the $directory directory...${NC}"
    sleep 1
    mkdir "$directory" || { echo -e "${RED}Failed to create the $directory directory.${NC}"; exit 1; }
    cd "$directory" || { echo -e "${RED}Failed to enter the $directory directory.${NC}"; exit 1; }

    echo -e "${LIGHTBLUE}Generating default project structure...${NC}"
    sleep 1
    mkdir -p ./storage/tokens; echo -e "${GREEN} $directory/storage/tokens${NC}"
    mkdir -p ./storage/configs; echo -e "${GREEN} $directory/storage/configs${NC}"
    mkdir -p ./storage/projects; echo -e "${GREEN} $directory/storage/projects${NC}"
    mkdir -p ./storage/global; echo -e "${GREEN} $directory/storage/global${NC}"

    echo -e "${LIGHTBLUE}Generating RSA keys and OpenSSL base64 tokens...${NC}"
    if ! openssl genrsa -out ./storage/tokens/private.pem 2048; then
        echo -e "${RED}Failed to generate RSA private key.${NC}"
        exit 1
    fi

    if ! openssl rsa -in ./storage/tokens/private.pem -pubout -out ./storage/tokens/public.key; then
        echo -e "${RED}Failed to generate RSA public key.${NC}"
        exit 1
    fi

    if ! openssl rand -base64 32 > ./storage/tokens/server.key; then
        echo -e "${RED}Failed to generate OpenSSL base64 token.${NC}"
        exit 1
    fi

    if ! openssl rand -base64 32 > ./storage/tokens/aes.key; then
        echo -e "${RED}Failed to generate AES OpenSSL base64 token.${NC}"
        exit 1
    fi

    if ! openssl rand -base64 64 > ./storage/tokens/jwt.key; then
        echo -e "${RED}Failed to generate JWT OpenSSL base64 token.${NC}"
        exit 1
    fi

    sleep 1
    echo -e "${LIGHTBLUE}Creating docker-compose.yml file...${NC}"

    if curl -o docker-compose.yml "$GIST_URL"; then
        echo -e "${GREEN} $directory/docker-compose.yml${NC}"
    else
        echo -e "${RED}Failed to fetch docker-compose file from GitHub Gist.${NC}"
        exit 1
    fi

    sleep 1
    echo -e "${LIGHTBLUE}Collecting configuration information...${NC}"
    read -p "Enter admin username: " admin_username
    read -s -p "Enter admin password: " admin_password
    echo ""
    while true; do
        read -p "Enter admin email: " admin_email
        if [[ "$admin_email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$ ]]; then
            break
        else
            echo -e "${RED}Invalid email address. Please enter a valid email.${NC}"
        fi
    done
    echo -e "${RED}Important! If answered 'no', you'll be prompted with configuring your custom database!${NC}"
    read -p "Do you want to install database service automatically? (y/n): " db_choice

    if [[ "$db_choice" == "yes" || "$db_choice" == "y" ]]; then
        read -p "Enter database user: " database_user
        read -s -p "Enter database password: " database_password
        echo ""

        DB_HOST="localhost"
        DB_PORT="5432"
        DB_USER=$database_user
        DB_PASSWORD=$database_password
        DB_DB="ultima"

    elif [[ "$db_choice" == "no" || "$db_choice" == "n" ]]; then
        echo -e "${RED}Support is only for PostgreSQL databases for now!${NC}"
        read -p "Enter database host: " custom_database_host
        read -p "Enter database port: " custom_database_port
        read -p "Enter database user: " custom_database_user
        read -s -p "Enter database password: " custom_database_password
        echo ""
        read -p "Enter database db: " custom_database_db

        DB_HOST=$custom_database_host
        DB_PORT=$custom_database_port
        DB_USER=$custom_database_user
        DB_PASSWORD=$custom_database_password
        DB_DB=$custom_database_db
    fi

    # Create .env file for custom database setup
    echo -e "${LIGHTBLUE}Creating secret environmental file...${NC}"
    cat <<EOF > .env
    # DATABASE CONFIGURATION
    POSTGRES_HOST=$DB_HOST
    POSTGRES_PORT=$DB_PORT
    POSTGRES_USER=$DB_USER
    POSTGRES_PASSWORD=$DB_PASSWORD
    POSTGRES_DB=$DB_DB

    # PGADMIN CONFIGURATION
    PGADMIN_DEFAULT_EMAIL=$admin_email
    PGADMIN_DEFAULT_PASSWORD=$admin_password
EOF

    sleep 1
    echo -e "${GREEN}Installation completed!${NC}"
    sleep 1
    # Completion message
    echo -e ""
    echo -e ""
    echo -e ""
    echo -e ""
    echo -e ""
    echo -e ""
    echo -e "${GREEN}Thanks for installing panel Ultima!${NC}"
    echo -e "Documentation: ${LIGHTBLUE}https://docs.ultima.com${NC}"
    echo -e ""
    echo -e "To start your services, run:"
    echo -e " ${GREEN}$ ${LIGHTBLUE}cd $directory${NC}"
    echo -e " ${GREEN}$ ${LIGHTBLUE}docker-compose up -d${NC}"
    echo -e ""
    echo -e "For more information, run:"
    echo -e " ${GREEN}$ ${LIGHTBLUE}ultima help${NC}"
    echo -e ""
    echo -e "If any errors occur during installation,"
    echo -e "contact us on our discord: ${LIGHTBLUE}https://discord.ultilize.com${NC}"
    echo -e ""
}