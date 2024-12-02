# Advanced Automated Reconnaissance Script
## 🕵️ Overview
This Bash script provides an automated, comprehensive subdomain reconnaissance tool designed for cybersecurity professionals and ethical penetration testers. The script automates the process of domain enumeration, subdomain discovery, and online status checking.
## ✨ Features

🔍 Automated subdomain enumeration
🌐 Multi-tool subdomain discovery
🔗 Redirect tracking and analysis
🛠️ Automatic tool installation
📊 Detailed result logging

## 🔧 Prerequisites

Linux OS (Debian/Ubuntu recommended)
Sudo access
Python 3
pip3
Go (will be installed if not present)

## 📦 Tools Installed
The script automatically installs:

Sublist3r
Amass
Dirsearch
Httpx
Go (if not present)

## 🚀 Installation

**Clone the repository:**
git clone https://github.com/backcoc/recon_automation.git
cd recon_automation
chmod +x recon.sh

**Make the script executable:**
bashCopychmod +x recon.sh


##💻 Usage
Run the script with sudo:
bashCopysudo ./recon.sh
Input Options

Single domain: example.com
Domain list file: /path/to/domains.txt

## 📁 Output Files

domains.txt: Input domains
subdomains/: Individual domain subdomain results
redirects/: Redirect information
final_subdomains.txt: Unique subdomains
unique_redirects.txt: Unique redirect URLs

## 🔒 Legal and Ethical Considerations
Important:

Use this tool only on domains you own or have explicit permission to test
Unauthorized scanning can be illegal
Respect website terms of service and local laws

## 🤝 Contributing

Fork the repository
Create your feature branch
Commit changes
Push to the branch
Create a Pull Request

## ⚠️ Disclaimer
This tool is for educational and authorized testing purposes only. The author is not responsible for misuse.
## 🐛 Reporting Issues
Report bugs and suggestions on the GitHub issues page.
## 💡 Future Improvements

Add more reconnaissance tools
Implement advanced filtering
Create reporting mechanisms
Enhance error handling


Cybersecurity Tip: Always obtain proper authorization before performing any reconnaissance activities.
