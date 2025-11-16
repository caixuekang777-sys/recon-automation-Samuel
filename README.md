# recon-automation-Samuel
# Recon Automation Tool

A simple Bash script to automate basic subdomain enumeration workflows. This project was created to learn recon automation for bug bounties and penetration testing.

This script takes a list of domains, runs subfinder to find subdomains, uses anew to store unique results, and finally uses httpx to filter live hosts.

bash

git clone https://github.com/caixuekang777-sys/recon-automation-Samuel.git

cd recon-automation-alief

# Install Subfinder
go install -v [github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest](https://github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest)

# Install HTTPX
go install -v [github.com/projectdiscovery/httpx/cmd/httpx@latest](https://github.com/projectdiscovery/httpx/cmd/httpx@latest)

# Install Anew
go install -v [github.com/tomnomnom/anew@latest](https://github.com/tomnomnom/anew@latest)

# Move all tools to /usr/local/bin so they can be found
sudo mv ~/go/bin/subfinder /usr/local/bin/
sudo mv ~/go/bin/httpx /usr/local/bin/
sudo mv ~/go/bin/anew /usr/local/bin/

chmod +x scripts/recon-auto.sh

./scripts/recon-auto.sh

recon-automation-kali/
├── input/
│   └── domains.txt              # File input domains
├── output/
│   ├── all-subdomains.txt       # Semua subdomain unik
│   └── live.txt                 # Host yang hidup (hasil akhir)
├── logs/
│   ├── progress.log             # Log proses dengan timestamp
│   └── errors.log               # Log error selama eksekusi
├── scripts/
│   └── recon-auto.sh            # Skrip utama (executable)
└── README.md                    # Dokumentasi ini

*Script Explanation (scripts/recon-auto.sh)
This script is designed to be portable and secure. Here's how it works:

**Path Configuration (Lines 13-16)
SCRIPT_DIR & PROJECT_ROOT: This section automatically detects where the script is located. This allows you to run the script from any directory without breaking the path to input or output files.

**log() Function (Lines 29-34)
This is a custom logging function. Any message sent to the “message” log will be printed to the screen AND added to logs/progress.log using tee -a, complete with a timestamp.

**Dependency Checking (Lines 40-52)
The script stops if it cannot find subfinder, anew, or httpx in the system PATH. This prevents the script from running halfway and failing.

**Enumeration (Loop) (Lines 70-87)
The script reads the input file/domains.txt line by line using while read domain.
This allows the script to process one domain at a time

**Core Pipeline (Line 80)
subfinder -d “$domain” -silent | anew “$OUTPUT_SUBDOMAINS”
This is the “heart” of the script. The output (subdomains) from subfinder is piped (|) directly to anew.
anew then checks whether the subdomain already exists in output/all-subdomains.txt. If not, it adds it to the file. This is very efficient for deduplication.

**Error Handling (Line 80)
2>> “$ERROR_LOG”: This is an important part. The number 2 represents Standard Error (stderr). >> means adding to the file.
Any error messages from subfinder or anew (e.g., “API key not configured”) will not clutter the screen but will be neatly redirected to logs/errors.log for later review.

**Live Host Checking (Lines 96-103)
httpx -l “$OUTPUT_SUBDOMAINS” ... -o “$OUTPUT_LIVE”
After all subdomains are collected, httpx reads (-l) the all-subdomains.txt file and checks which ones are live, then saves (-o) the results to live.txt.

**Final Report (Lines 110-120)
wc -l < “$FILE”: This is an efficient way to count the number of lines (-l) in a file.
The script ends by giving you a summary of how many total subdomains and live hosts it found.

***Terminal Execution

Displays scripts while they are running and final reports
<img width="1600" height="865" alt="image" src="https://github.com/user-attachments/assets/cc94ce6b-3e5a-4dba-8769-ec543be0fb74" />
<img width="1600" height="865" alt="image" src="https://github.com/user-attachments/assets/7412c65e-b52a-419b-8881-7a07a742908f" />

Results live.txt
Displays the contents of the output/live.txt file after the script has finished
<img width="1600" height="865" alt="image" src="https://github.com/user-attachments/assets/0e8d1f26-1d85-48af-94d6-c164bfedbc4f" />


