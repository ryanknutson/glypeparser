#!/bin/bash

# bash-spinner by tlatsas
function _spinner() {
    # $1 start/stop
    #
    # on start: $2 display message
    # on stop : $2 process exit status
    #           $3 spinner function pid (supplied from stop_spinner)

    local on_success="DONE"
    local on_fail="FAIL"
    local white="\e[1;37m"
    local green="\e[1;32m"
    local red="\e[1;31m"
    local nc="\e[0m"

    case $1 in
        start)
            # calculate the column where spinner and status msg will be displayed
            let column=$(tput cols)-${#2}-8
            # display message and position the cursor in $column column
            echo -ne ${2}
            printf "%${column}s"

            # start spinner
            i=1
            sp='\|/-'
            delay=${SPINNER_DELAY:-0.15}

            while :
            do
                printf "\b${sp:i++%${#sp}:1}"
                sleep $delay
            done
            ;;
        stop)
            if [[ -z ${3} ]]; then
                echo "spinner is not running.."
                exit 1
            fi

            kill $3 > /dev/null 2>&1

            # inform the user uppon success or failure
            echo -en "\b["
            if [[ $2 -eq 0 ]]; then
                echo -en "${green}${on_success}${nc}"
            else
                echo -en "${red}${on_fail}${nc}"
            fi
            echo -e "]"
            ;;
        *)
            echo "invalid argument, try {start/stop}"
            exit 1
            ;;
    esac
}

function start_spinner {
    # $1 : msg to display
    _spinner "start" "${1}" &
    # set global spinner pid
    _sp_pid=$!
    disown
}

function stop_spinner {
    # $1 : command exit status
    _spinner "stop" $1 $_sp_pid
    unset _sp_pid
}

gp="Glype Parser v1\nUsage gparse.sh {arguments}\n-h Show this help message and exit.\n-p [path] Pick the path of your logs. If no path is selected, current directory will be used."

# Set command switches
while getopts ":hp:" opt; do
  case $opt in
    h)
      echo -e $gp
      exit 1
      ;;
    \?)
      echo "Invalid option: -$OPTARG"
      echo -e $gp
      exit 1
      ;;
    p)
      cd ${OPTARG}
      ;;
    :)
      echo "Error: option -$OPTARG requires an argument."
      echo -e $gp
      exit 1
      ;;
  esac
done

GREN='\033[1;32m'
NC='\033[0m' # No Color

# Set the date variable.
now=$(date +"%m_%d_%y")

# Remove old files from today if they exist (more for a debugging use)
{
rm logfull_$now.log logstrip_$now.log logmin_$now.log
} &> /dev/null

# Test if there are logfiles in specified directory
{
cat *.log
} &> /dev/null
if [ "$?" = "0" ]; then
    printf "[${GREN}Beginning Parse${NC}]\n"
else
    echo "No logs found in specified directory!" 1>&2
    exit 1
fi

# Combine all the log files into one file.
start_spinner 'Condensing logs'
cat *.log > logfull_$now.log
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

# Ask user if they want to move old logs into a logsbu_$now folder.
read -r -p "Do you want to move old logs into a folder? [y/n] " response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]
then
    mkdir logbu_$now
    mv *.log logbu_$now/
    printf "[${GREN}Moved logs successfully${NC}]"
else
    printf "[${GREN}Didn't move anything${NC}]"
fi

echo
echo "Full, condensed log       logfull_$now.log"
echo "Log with only urls        logstrip_$now.log"
echo "Minimal log               logmin_$now.log"
