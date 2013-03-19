#!/bin/bash


# Execute "export DEBUG=1" to debug this script.
# Set value to 2 to debug this script and the scripts called within this script.
# Set value to 3,4,5 and so on to increase the nesting level of the scripts to be debugged.
[[ $DEBUG -gt 0 ]] && set -x; export DEBUG=$(($DEBUG - 1))


#
# Given an IP address obtain the ELB URL if the IP is actually pointing to an Elastic Load Balancer.
#


# include all the utility scripts
source $ELASTICBEANSTALK_APP_SCRIPT_DIR/include/include.sh


display_usage()
{
    echo -e "\nUsage: $0 ip\n"
}

# Check the argument count
if [ ! $# == 1 ]; then
    display_usage
    exit 2
fi


ip=$1
result=""

aelbURL=$(elb-describe-lbs | awk '{print $3}')

for elbURL in $aelbURL
do
    elbIP=$(getIPOfURL $elbURL)
    if ([ "$elbIP" == "$ip" ]) then
        result=$elbURL
        break
    fi
done


echo $result
