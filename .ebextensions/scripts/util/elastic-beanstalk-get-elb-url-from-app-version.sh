#!/bin/bash


# Execute "export DEBUG=1" to debug this script.
# Set value to 2 to debug this script and the scripts called within this script.
# Set value to 3,4,5 and so on to increase the nesting level of the scripts to be debugged.
[[ $DEBUG -gt 0 ]] && set -x; export DEBUG=$(($DEBUG - 1))

#
# Given Beanstalk application version obtain the end point URL (URL of the Load Balancer).
#


display_usage()
{
    echo -e "\nUsage: $0 appVersionName\n"
}

# Check the argument count
if [ ! $# == 1 ]; then
    display_usage
    exit 2
fi


appVersionName=$1


# Using the app version name obtain the beanstalk environment name
elbURL=$(elastic-beanstalk-describe-environments -j | grep -ioP "EndpointURL.*?\"VersionLabel\":\"$appVersionName\"" | cut -d, -f1 | cut -d: -f2 | sed s/\"//g)

if [ -z "$elbURL" ]; then
    exit 1
fi

echo $elbURL
