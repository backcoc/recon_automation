#!/bin/bash

# Logging and Error Handling Configuration
LOG_FILE="recon_log.txt"
ERROR_FILE="recon_errors.txt"

# Color Codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging Function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    # Console output
    case "$level" in
        "INFO")
            echo -e "${BLUE}[INFO]${NC} $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${NC} $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}[WARNING]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message"
            ;;
    esac
    
    # Log to file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Error Handling Wrapper
safe_execute() {
    local command="$1"
    local error_level="${2:-WARNING}"
    local error_message="${3:-Command execution failed}"
    
    # Attempt to execute the command
    output=$(eval "$command" 2>&1)
    status=$?
    
    # Check command status
    if [ $status -ne 0 ]; then
        # Log the error
        log_message "ERROR" "$error_message: $output"
        echo "$output" >> "$ERROR_FILE"
        
        # Determine error handling based on level
        case "$error_level" in
            "CRITICAL")
                log_message "ERROR" "Critical error occurred. Exiting script."
                exit 1
                ;;
            "WARNING")
                log_message "WARNING" "Non-critical error. Continuing execution."
                return 1
                ;;
            "IGNORE")
                log_message "WARNING" "Ignoring error as requested."
                return 0
                ;;
        esac
    else
        # Successful execution
        log_message "SUCCESS" "Command executed successfully: $command"
        return 0
    fi
}

# Comprehensive Tool Installation Function
install_recon_tools() {
    log_message "INFO" "Starting reconnaissance tools installation"
    
    # Associative array of tools with installation commands
    declare -A TOOLS=(
        [subfinder]="go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
        [assetfinder]="go install github.com/tomnomnom/assetfinder@latest"
        [amass]="go install github.com/owasp-amass/amass/v4/cmd/amass@latest"
        [httpx]="go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest"
    )

    # Ensure Go is installed
    if ! command -v go &> /dev/null; then
        safe_execute "sudo apt-get update && sudo apt-get install -y golang-go" "CRITICAL" "Failed to install Go"
    fi

    # Install tools
    for tool in "${!TOOLS[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            safe_execute "${TOOLS[$tool]}" "WARNING" "Failed to install $tool"
            safe_execute "sudo ln -sf ~/go/bin/$tool /usr/local/bin/$tool" "IGNORE" "Failed to create symlink for $tool"
        else
            log_message "INFO" "$tool is already installed"
        fi
    done

    log_message "SUCCESS" "Tool installation process completed"
}

# Advanced Subdomain Enumeration with Robust Error Handling
advanced_subdomain_enumeration() {
    local domain="$1"
    local output_dir="subdomains/${domain}"
    
    # Create output directory
    mkdir -p "$output_dir"

    log_message "INFO" "Starting advanced subdomain enumeration for $domain"

    # Enumeration methods with specific error handling
    local methods=(
        "subfinder -d $domain -o ${output_dir}/subfinder_subdomains.txt"
        "assetfinder --subs-only $domain > ${output_dir}/assetfinder_subdomains.txt"
        "amass enum -d $domain -o ${output_dir}/amass_subdomains.txt"
    )

    # Track successful and failed methods
    local successful_methods=0
    local failed_methods=0

    # Execute each method with granular error handling
    for method in "${methods[@]}"; do
        if safe_execute "$method" "WARNING" "Subdomain enumeration method failed"; then
            ((successful_methods++))
        else
            ((failed_methods++))
        fi
    done

    # Combine results if any method succeeded
    if [ $successful_methods -gt 0 ]; then
        safe_execute "cat ${output_dir}/*_subdomains.txt | sort -u > ${output_dir}/all_subdomains.txt" "CRITICAL" "Failed to combine subdomain results"
        
        # Probe for live hosts
        safe_execute "cat ${output_dir}/all_subdomains.txt | httpx -silent -title -status-code -tech-detect -o ${output_dir}/live_subdomains.txt" "WARNING" "Live host probing failed"
    else
        log_message "ERROR" "No subdomain enumeration method succeeded for $domain"
        return 1
    fi

    # Generate report
    log_message "SUCCESS" "Subdomain enumeration completed for $domain"
    log_message "INFO" "Total unique subdomains: $(wc -l < "${output_dir}/all_subdomains.txt")"
    log_message "INFO" "Total live subdomains: $(wc -l < "${output_dir}/live_subdomains.txt")"

    return 0
}

# Main Execution Function
main() {
    # Clear previous log files
    > "$LOG_FILE"
    > "$ERROR_FILE"

    log_message "INFO" "Reconnaissance script started"

    # Install tools
    install_recon_tools

    # Domain input
    log_message "INFO" "Please enter a domain or path to a domain list"
    read -r input

    # Validate input
    if [ -z "$input" ]; then
        log_message "ERROR" "No input provided. Exiting."
        exit 1
    fi

    # Process domains
    if [ -f "$input" ]; then
        # Input is a file
        log_message "INFO" "Processing domains from file: $input"
        while IFS= read -r domain; do
            # Trim whitespace
            domain=$(echo "$domain" | xargs)
            
            # Skip empty lines
            [ -z "$domain" ] && continue

            # Attempt enumeration, continue if fails
            if ! advanced_subdomain_enumeration "$domain"; then
                log_message "WARNING" "Skipping domain due to enumeration failure: $domain"
            fi
        done < "$input"
    else
        # Single domain input
        advanced_subdomain_enumeration "$input"
    fi

    log_message "SUCCESS" "Reconnaissance script completed"
}

# Trap unexpected errors
trap 'log_message "ERROR" "Unexpected error occurred at line $LINENO"' ERR

# Execute main function
main
