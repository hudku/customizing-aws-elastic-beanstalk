#!/bin/bash


# Execute "export DEBUG=1" to debug this script.
# Set value to 2 to debug this script and the scripts called within this script.
# Set value to 3,4,5 and so on to increase the nesting level of the scripts to be debugged.
[[ $DEBUG -gt 0 ]] && set -x; export DEBUG=$(($DEBUG - 1))

#
# Given an ELB URL obtain its Hosted Zone ID. Needed to make Route53 entries.
#


display_usage()
{
    echo -e "\nUsage: $0 elbURL\n"
}

# Check the argument count
if [ ! $# == 1 ]; then
    display_usage
    exit 2
fi


elbURL=$1

elbHostedZoneID=$(elb-describe-lbs --show-long | grep -i $elbURL | cut -d, -f5)

echo $elbHostedZoneID
