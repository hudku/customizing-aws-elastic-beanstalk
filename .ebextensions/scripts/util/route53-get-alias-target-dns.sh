#!/bin/bash


# Execute "export DEBUG=1" to debug this script.
# Set value to 2 to debug this script and the scripts called within this script.
# Set value to 3,4,5 and so on to increase the nesting level of the scripts to be debugged.
[[ $DEBUG -gt 0 ]] && set -x; export DEBUG=$(($DEBUG - 1))


#
# Retrieves the value of the AliasTarget record for the specified Route53 DNS entry name
#


display_usage()
{
    echo -e "\nUsage: $0 route53_RR_Name\n"
}

# Check argument count
if [ ! $# == 1 ]; then
    display_usage
    exit 2
fi


dnsEntryName=$1

awsAccountKeyName=$AWS_ACCOUNT_KEY_NAME


# Extract host name from the dns entry name
hostName=$(echo $dnsEntryName | grep -o "[^\.]*\.[^\.]*\.$")


# dnscurl common options
optionsDNSCurl="-- -s -H \"Content-Type: text/xml; charset=UTF-8\""

# Route53 API settings
urlRoute53API="https://route53.amazonaws.com/2012-02-29"


# Get Route53 HostedZoneId
allHostedZones=$(dnscurl.pl --keyname $awsAccountKeyName $optionsDNSCurl -X GET $urlRoute53API/hostedzone 2>/dev/null)
hostNameSearch="ListHostedZonesResponse/HostedZones/HostedZone[Name=\"$hostName\"]/Id"
hostedZoneId=$(echo $allHostedZones | xpath $hostNameSearch 2>/dev/null | awk -F'[<|>]' '/Id/{print $3}' | cut -d/ -f3)
if ([ -z $hostedZoneId ]) then
    exit 1
fi

# Obtain all the resource record sets for the hosted zone id
allRecords=$(dnscurl.pl --keyname $awsAccountKeyName $optionsDNSCurl -X GET $urlRoute53API/hostedzone/$hostedZoneId/rrset 2>/dev/null)

# Obtain the value of the DNS AliasTarget
dnsNameSearch="ListResourceRecordSetsResponse/ResourceRecordSets/ResourceRecordSet[Name=\"$dnsEntryName\"]/AliasTarget/DNSName"
dnsName=$(echo $allRecords | xpath $dnsNameSearch 2>/dev/null | awk -F'[<|>]' '/DNSName/{print $3}' | cut -d/ -f3 | sed 's/.$//')
if ([ -z $dnsName ]) then
    exit 1
fi


echo $dnsName
