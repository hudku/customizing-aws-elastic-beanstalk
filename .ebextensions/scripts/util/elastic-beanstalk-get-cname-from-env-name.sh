#!/bin/bash


# Execute "export DEBUG=1" to debug this script.
# Set value to 2 to debug this script and the scripts called within this script.
# Set value to 3,4,5 and so on to increase the nesting level of the scripts to be debugged.
[[ $DEBUG -gt 0 ]] && set -x; export DEBUG=$(($DEBUG - 1))

#
# Given Beanstalk environment name obtain the CNAME.
#


display_usage()
{
    echo -e "\nUsage: $0 envName\n"
}

# Check the argument count
if [ ! $# == 1 ]; then
    display_usage
    exit 2
fi


envName=$1


elbURL=$(elastic-beanstalk-describe-environments -e $envName -j | python -mjson.tool | grep CNAME | awk '{print $2}' | sed s/\"//g | sed s/,//g)

if [ -z $elbURL ]; then
    exit 1
fi

echo $elbURL
