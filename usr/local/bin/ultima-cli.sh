#!/bin/bash

# Define color codes for enhancing script output readability
LIGHTBLUE='\033[1;34m'
AQUA='\e[96m'
LIGHTRED='\033[1;31m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# URL for the docker-compose file hosted on GitHub Gist
GIST_URL="https://gist.githubusercontent.com/PhillipSwann-main/3ffd49604024e24acb5cf64b09680a33/raw/c2ecd1a2cefe94635fd03e4cc79e3fa562e66ade/docker-compose.yml"

# Function to check and install Docker on the system
install_docker() {
    echo -e "${LIGHTBLUE}Checking for Docker...${NC}"
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo -e "${LIGHTRED}Docker engine not found, installing...${NC}"
        # Detect OS for appropriate Docker installation
        os_name="$(. /etc/os-release && echo "$ID")"
        os_version_codename="$(. /etc/os-release && echo "$VERSION_CODENAME")"
        # Install Docker based on detected OS
        case "$os_name" in
            debian|ubuntu|raspbian)
                # Commands for Debian, Ubuntu, and Raspbian
                for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove -y $pkg; done
                sudo apt-get update
                sudo apt-get install -y ca-certificates curl gnupg
                sudo install -m 0755 -d /etc/apt/keyrings
                curl -fsSL https://download.docker.com/linux/$os_name/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
                sudo chmod a+r /etc/apt/keyrings/docker.gpg
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$os_name $os_version_codename stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                sudo apt-get update
                sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
                ;;
            centos)
                # Commands for CentOS
                sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
                sudo yum install -y yum-utils
                sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
                sudo systemctl start docker
                ;;
            fedora)
                # Commands for Fedora
                sudo dnf remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine
                sudo dnf -y install dnf-plugins-core
                sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
                sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
                sudo systemctl start docker
                ;;
            *)
                echo -e "${RED}OS not supported or cannot be automatically determined.${NC}"
                echo "Please install Docker manually from the official installation docs."
                exit 1
                ;;
        esac

        # Verify Docker installation
        if ! sudo docker run hello-world &> /dev/null; then
            echo -e "${RED}Docker installation failed. Please check the installation steps.${NC}"
            exit 1
        else
            echo -e "${GREEN}Docker installation successful.${NC}"
        fi
    else
        echo -e "${GREEN}Docker engine found and ready to run.${NC}"
    fi
}

# Function to handle the 'install' command
install_command() {
    # Optional directory argument, default to "ultima" if not provided
    local directory=${1:-ultima}

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

    echo -e "${LIGHTBLUE}Generating RSA keys and OpenSSL base64 token...${NC}"
    mkdir -p ./storage/tokens
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
    read -p "Do you want to install database service automatically? (yes/no): " db_choice

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
    echo -e "${GREEN}Thanks for installing panel Ultima!${NC}"
    echo -e "Documentation: ${LIGHTBLUE}https://docs.ultima.com${NC}"
    echo -e ""
    echo -e "To start your services, run:"
    echo -e " ${GREEN}$ ${LIGHTBLUE}cd $directory${NC}"
    echo -e " ${GREEN}$ ${LIGHTBLUE}docker-compose up -d${NC}"
    echo -e ""
    echo -e "For more info, run:"
    echo -e " ${GREEN}$ ${LIGHTBLUE}ultima help${NC}"
    echo -e ""
    echo -e "If any errors occur during installation,"
    echo -e "contact us on our discord: ${LIGHTBLUE}https://discord.ultilize.com${NC}"
    echo -e ""
}

# Function to handle the 'help' command
help_command() {
    echo "Ultima CLI Help:"
    echo "  install - Set up a new Ultima project"
    echo "  help - Show this help message"
}

set_directory() {
    local dir=${1:-ultima}  # Default to current directory if not provided

    while : ; do
        if [[ -f "$dir/.env" && -f "$dir/docker-compose.yml" ]]; then
            echo -e "${GREEN}Project was found in '$dir'!${NC}"
            break
        else
            if [[ "$dir" == "." ]]; then
                echo -e "${RED}Could not find .env and docker-compose.yml in the current directory.${NC}"
            else
                echo -e "${RED}Could not find .env and docker-compose.yml in '${dir}'.${NC}"
            fi
            read -p "Enter the directory name or path where these files are located: " dir
            dir=${dir:-.}  # Default to current directory if input is empty
        fi
    done
    selected_directory="$dir"
}

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

# Function to join arguments
join_args() {
    local IFS=" " # set the internal field separator to space
    echo "$*"
}

# Main command routing
command=$(join_args "$@")

case "$command" in
    "install"*)
        # Extract the directory argument if provided
        directory=$(echo "$command" | cut -d' ' -f2)
        install_command "$directory"
        ;;
    "update")
        update_command
        ;;
    "change database")
        change_database_command
        ;;
    "change credentials")
        change_credentials_command
        ;;
    "help")
        help_command
        ;;
    *)
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
        echo -e "${GREEN}$ ${LIGHTBLUE}help                   ${NC}Show this help message"
        echo -e ""
        ;;
esac