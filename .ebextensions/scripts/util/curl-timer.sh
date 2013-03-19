#!/bin/bash


# Execute "export DEBUG=1" to debug this script.
# Set value to 2 to debug this script and the scripts called within this script.
# Set value to 3,4,5 and so on to increase the nesting level of the scripts to be debugged.
[[ $DEBUG -gt 0 ]] && set -x; export DEBUG=$(($DEBUG - 1))


#
# Accesses all the specified URLs and reports the data transfer time
#


display_usage()
{
    echo -e "\nUsage: $0 URL [URL]...\n"
}

# Check the arguments
if [ $# -lt 1 ]; then
    display_usage
    exit 2
fi


#
# Report data transfer time by accessing the specified URL
#
 
while [ $# -gt 0 ]; do
    echo $1

    curl -so /dev/null -w "Pre-Transfer: %{time_pretransfer} Start-Transfer: %{time_starttransfer} Total: %{time_total} Size: %{size_download}\n" "$1"
        
    shift
done
