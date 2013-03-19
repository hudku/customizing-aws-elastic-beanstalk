#!/bin/bash


# Execute "export DEBUG=1" to debug this script.
# Set value to 2 to debug this script and the scripts called within this script.
# Set value to 3,4,5 and so on to increase the nesting level of the scripts to be debugged.
[[ $DEBUG -gt 0 ]] && set -x; export DEBUG=$(($DEBUG - 1))

#
# Given the end point URL (URL of the Load Balancer) obtain Beanstalk environment name.
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


# Using the elb URL obtain the beanstalk environment name
envName=$(elastic-beanstalk-describe-environments -j | grep -io "\"EndpointURL\":\"$elbURL\",\"EnvironmentId\":\"[^\"]*\",\"EnvironmentName\":\"[^\"]*\"" | cut -d, -f3 | cut -d: -f2 | sed s/\"//g)

if [ -z $envName ]; then
    exit 1
fi

echo $envName
