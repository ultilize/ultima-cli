#!/bin/bash

# Include global variables
source "${BASE_DIR}/globals.sh"

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