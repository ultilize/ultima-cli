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