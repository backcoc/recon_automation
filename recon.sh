#!/bin/bash
# Advanced Automated Reconnaissance Script

# Color codes for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check and install tools
install_tools() {
    echo -e "${YELLOW}Checking and installing required tools...${NC}"
    
    # List of tools to check and install
    TOOLS=("sublist3r" "amass" "dirsearch" "httpx" "go")
    
    # Check if Go is installed (required for some tools)
    if ! command -v go &> /dev/null; then
        echo -e "${RED}Go is not installed. Installing Go...${NC}"
        sudo apt-get update
        sudo apt-get install -y golang-go
    fi

    # Install/update tools
    for tool in "${TOOLS[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            echo -e "${YELLOW}Installing $tool...${NC}"
            case "$tool" in
                "sublist3r")
                    sudo pip3 install sublist3r
                    ;;
                "amass")
                    go install github.com/owasp-amass/amass/v4/cmd/amass@latest
                    sudo ln -s ~/go/bin/amass /usr/local/bin/amass
                    ;;
                "dirsearch")
                    git clone https://github.com/maurosoria/dirsearch.git
                    cd dirsearch
                    sudo pip3 install -r requirements.txt
                    sudo ln -s "$(pwd)/dirsearch.py" /usr/local/bin/dirsearch
                    cd ..
                    ;;
                "httpx")
                    go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
                    sudo ln -s ~/go/bin/httpx /usr/local/bin/httpx
                    ;;
            esac
        else
            echo -e "${GREEN}$tool is already installed.${NC}"
        fi
    done
}

# Function to acquire domain or domain list
acquire_domains() {
    echo -e "${YELLOW}Enter a domain or path to a file containing a list of domains:${NC}"
    read input
    
    # Validate input
    if [ -z "$input" ]; then
        echo -e "${RED}No input provided. Exiting.${NC}"
        exit 1
    fi

    # Create domains file
    if [ -f "$input" ]; then
        cat "$input" > domains.txt
    else
        echo "$input" > domains.txt
    fi
    echo -e "${GREEN}Domains saved to domains.txt${NC}"
}

# Enhanced subdomain enumeration with redirect handling
enumerate_subdomains() {
    mkdir -p subdomains redirects

    # Temporary files for tracking
    > redirect_urls.txt
    > unique_redirects.txt
    > all_subdomains.txt

    while read domain; do
        echo -e "${YELLOW}Processing domain: $domain${NC}"

        # Subdomain enumeration
        sublist3r -d "$domain" -o "subdomains/${domain}_sublist3r.txt"
        amass enum -d "$domain" -o "subdomains/${domain}_amass.txt"
        
        # Directory search
        dirsearch -u "https://$domain" -o "subdomains/${domain}_dirsearch.txt"

        # Advanced subdomain and redirect analysis
        cat "subdomains/${domain}_sublist3r.txt" "subdomains/${domain}_amass.txt" | sort -u > "subdomains/${domain}_combined.txt"
        
        # Check online status with redirect information
        cat "subdomains/${domain}_combined.txt" | httpx -silent -status-code -title -location -o "redirects/${domain}_httpx.txt"

        # Parse redirects and unique URLs
        grep -E "^\[" "redirects/${domain}_httpx.txt" | while read -r line; do
            status=$(echo "$line" | grep -oP '\[\K[^]]+' | head -1)
            url=$(echo "$line" | grep -oP 'https?://[^\s]+')
            location=$(echo "$line" | grep -oP 'Location:\s*\K\S+')
            
            # Check for 302 or 200 status
            if [[ "$status" =~ ^(200|302)$ ]]; then
                if [ -n "$location" ]; then
                    echo "$location" >> redirect_urls.txt
                else
                    echo "$url" >> all_subdomains.txt
                fi
            fi
        done
    done < domains.txt

    # Remove duplicates
    sort -u redirect_urls.txt > unique_redirects.txt
    sort -u all_subdomains.txt > final_subdomains.txt
}

# Main execution
main() {
    # Ensure script is run with sudo
    if [[ $EUID -ne 0 ]]; then
       echo -e "${RED}This script must be run as root. Use sudo.${NC}" 
       exit 1
    fi

    # Install tools
    install_tools

    # Reconnaissance workflow
    acquire_domains
    enumerate_subdomains

    # Summary
    echo -e "\n${GREEN}Automated Reconnaissance Completed${NC}"
    echo -e "${YELLOW}Summary:${NC}"
    echo -e "Total domains processed: $(wc -l < domains.txt)"
    echo -e "Total unique subdomains found: $(wc -l < final_subdomains.txt)"
    echo -e "Total unique redirects found: $(wc -l < unique_redirects.txt)"
}

# Run main function
main
