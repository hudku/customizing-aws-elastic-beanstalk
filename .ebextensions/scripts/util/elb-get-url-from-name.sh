#!/bin/bash


# Execute "export DEBUG=1" to debug this script.
# Set value to 2 to debug this script and the scripts called within this script.
# Set value to 3,4,5 and so on to increase the nesting level of the scripts to be debugged.
[[ $DEBUG -gt 0 ]] && set -x; export DEBUG=$(($DEBUG - 1))


#
# Given an ELB name obtain its URL.
#


display_usage()
{
    echo -e "\nUsage: $0 elbName\n"
}

# Check the argument count
if [ ! $# == 1 ]; then
    display_usage
    exit 2
fi


elbName=$1

elbURL=$(elb-describe-lbs $elbName | awk '{print $2}')

echo $elbURL
