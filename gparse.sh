#!/bin/bash

echo "Parsing files..."

# Set the date variable.
now=$(date +"%m_%d_%y")

# Combine all the log files into one file.
cat *-*-*.log > logfull_$now.log

# Grep out the other stuff, only leaving http and https.
grep -o 'http://[^"]*' logfull_$now.log > logstrip_$now.log
grep -o 'https://[^"]*' logfull_$now.log >> logstrip_$now.log

# Keep only top level domains.
cat logstrip_$now.log | awk -F/ '{print $3}' > logmin1_$now.log

# Remove duplicates from the file.
sort -u logmin1_$now.log > logmin_$now.log

# Remove unsorted file.
rm logmin1_$now.log

echo "Done!"
