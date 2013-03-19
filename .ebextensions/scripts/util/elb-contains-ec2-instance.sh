#!/bin/bash


# Execute "export DEBUG=1" to debug this script.
# Set value to 2 to debug this script and the scripts called within this script.
# Set value to 3,4,5 and so on to increase the nesting level of the scripts to be debugged.
[[ $DEBUG -gt 0 ]] && set -x; export DEBUG=$(($DEBUG - 1))

#
# Given ELB name and EC2 instance id determine whether the EC2 instance is member of the specified ELB.
#


display_usage()
{
    echo -e "\nUsage: $0 elbName ec2InstanceId\n"
}

# Check the argument count
if [ $# -ne 2 ]; then
    display_usage
    exit 2
fi


elbName=$1
ec2InstanceId=$2

result=$(elb-describe-instance-health $elbName $ec2InstanceId | awk '{print $2}')

if ([ "$result" != "$ec2InstanceId" ]) then
    echo "no"
    exit 1
fi

echo "yes"
