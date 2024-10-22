#!/bin/bash

# Automated Reconnaissance Script

# Function to acquire domain or domain list
acquire_domains() {
    echo "Enter a domain or path to a file containing a list of domains:"
    read input

    if [ -f "$input" ]; then
        cat "$input" > domains.txt
    else
        echo "$input" > domains.txt
    fi

    echo "Domains saved to domains.txt"
}

# Function to perform subdomain enumeration
enumerate_subdomains() {
    mkdir -p subdomains
    while read domain; do
        echo "Enumerating subdomains for $domain"
        sublist3r -d "$domain" -o "subdomains/${domain}_sublist3r.txt"
        amass enum -d "$domain" -o "subdomains/${domain}_amass.txt"
        dirsearch -u "https://$domain" -o "subdomains/${domain}_dirsearch.txt"
    done < domains.txt
}

# Function to combine unique entries
combine_unique_entries() {
    cat subdomains/* | sort -u > all_subdomains.txt
    echo "Combined unique subdomains saved to all_subdomains.txt"
}

# Function to check online status with httpx
check_online_status() {
    cat all_subdomains.txt | httpx -silent -status-code -title -o online_subdomains.txt
    echo "Online subdomains saved to online_subdomains.txt"
}

# Main execution
acquire_domains
enumerate_subdomains
combine_unique_entries
check_online_status

echo "Automated reconnaissance completed"
echo "Summary:"
echo "Total domains processed: $(wc -l < domains.txt)"
echo "Total unique subdomains found: $(wc -l < all_subdomains.txt)"
echo "Total online subdomains: $(wc -l < online_subdomains.txt)"
