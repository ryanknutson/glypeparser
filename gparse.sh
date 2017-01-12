#!/bin/bash

source "$(pwd)/spinner.sh"

GREEN='\033[1;32m'
NC='\033[0m' # No Color
printf "[${GREEN}Beginning Parse${NC}]\n"

# Set the date variable.
now=$(date +"%m_%d_%y")

# Combine all the log files into one file.
start_spinner 'Condensing logs'
cat *-*-*.log > logfull_$now.log
stop_spinner $?

# Grep out the other stuff, only leaving http and https.
start_spinner 'Parsing http'
grep -o 'http://[^"]*' logfull_$now.log > logstrip_$now.log
stop_spinner $?

start_spinner 'Parsing https'
grep -o 'https://[^"]*' logfull_$now.log >> logstrip_$now.log
stop_spinner $?

# Keep only subdomains.
start_spinner 'Keeping only subdomains'
cat logstrip_$now.log | awk -F/ '{print $3}' > logmin1_$now.log
stop_spinner $?

# Remove duplicates from the file.
start_spinner 'Removing duplicates'
sort -u logmin1_$now.log > logmin_$now.log
stop_spinner $?

# Remove unsorted file.
start_spinner 'Removing unsorted file'
rm logmin1_$now.log
stop_spinner $?

echo
echo "Full, condensed log       logfull_$now.log"
echo "Log with only urls        logstrip_$now.log"
echo "Minimal log               logmin_$now.log"
