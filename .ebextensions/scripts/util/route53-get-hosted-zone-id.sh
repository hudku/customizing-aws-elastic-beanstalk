#!/bin/bash


# Execute "export DEBUG=1" to debug this script.
# Set value to 2 to debug this script and the scripts called within this script.
# Set value to 3,4,5 and so on to increase the nesting level of the scripts to be debugged.
[[ $DEBUG -gt 0 ]] && set -x; export DEBUG=$(($DEBUG - 1))


#
# Retrieves the Hosted Zone Id of the specified Route53 zone using route53 command line utility
#


display_usage()
{
    echo -e "\nUsage: $0 hostedZoneName\n"
}

# Exactly one argument should be supplied
if [ ! $# == 1 ]; then
    display_usage
    exit 2
fi



hostedZoneName=$1


route53HostedZoneID=$(route53 ls | sed -n -e '/'"$hostedZoneName"'/{g;1!p;};h' | awk '{print $3}')
if ([ -z $route53HostedZoneID ]) then
    echo "Could not find zone '$hostedZoneName' in route 53"
    exit 1
fi

echo $route53HostedZoneID
