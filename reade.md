# Automated Reconnaissance Script

**Description**:  
This script automates the reconnaissance process for domains. It performs subdomain enumeration, combines the results, and checks the online status of the discovered subdomains.

## Requirements

Make sure the following tools are installed before running the script:
- **Sublist3r**
- **Amass**
- **Dirsearch**
- **httpx**

You can install these tools with the following commands:

```bash
pip install sublist3r
go install -v github.com/OWASP/Amass/v3/...
git clone https://github.com/maurosoria/dirsearch.git
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
