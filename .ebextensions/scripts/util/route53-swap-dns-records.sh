#!/bin/bash


# Execute "export DEBUG=1" to debug this script.
# Set value to 2 to debug this script and the scripts called within this script.
# Set value to 3,4,5 and so on to increase the nesting level of the scripts to be debugged.
[[ $DEBUG -gt 0 ]] && set -x; export DEBUG=$(($DEBUG - 1))


#
# Swaps the specified Route53 DNS entry records
#


display_usage()
{
    echo -e "\nUsage: route53-swap-dns-records awsAccountKeyName dnsEntryName1 dnsEntryName2 [www]\n"
}

# Exactly one argument should be supplied
if [ ! $# == 3 ] && [ ! $# == 4 ]; then
    display_usage
    exit 2
fi


awsAccountKeyName=$1
dnsEntryName1=$2
dnsEntryName2=$3
prefixName=$4


# Extract host name from the dns entry name
hostName=$(echo $dnsEntryName1 | grep -o "[^\.]*\.[^\.]*\.$")


# dnscurl common options
optionsDNSCurl="-- -s -H \"Content-Type: text/xml; charset=UTF-8\""

# Route53 API settings
urlRoute53API="https://route53.amazonaws.com/2012-02-29"


# Get Route53 HostedZoneId
allHostedZones=$(dnscurl.pl --keyname $awsAccountKeyName $optionsDNSCurl -X GET $urlRoute53API/hostedzone 2>/dev/null)
hostNameSearch="ListHostedZonesResponse/HostedZones/HostedZone[Name=\"$hostName\"]/Id"
hostedZoneId=$(echo $allHostedZones | xpath $hostNameSearch 2>/dev/null | awk -F'[<|>]' '/Id/{print $3}' | cut -d/ -f3)
if ([ -z $hostedZoneId ]) then
    echo "Error: Failed to obtain hosted zone id for '$hostName' in Route53"
    exit 1
fi

# Obtain all the resource record sets for the hosted zone id
allRecords=$(dnscurl.pl --keyname $awsAccountKeyName $optionsDNSCurl -X GET $urlRoute53API/hostedzone/$hostedZoneId/rrset 2>/dev/null)

# Obtain AliasTarget records
dnsRecordSearch="ListResourceRecordSetsResponse/ResourceRecordSets/ResourceRecordSet[Name=\"$dnsEntryName1\"]"
dnsRecord1=$(echo $allRecords | xpath $dnsRecordSearch 2>/dev/null)

dnsRecordSearch="ListResourceRecordSetsResponse/ResourceRecordSets/ResourceRecordSet[Name=\"$dnsEntryName2\"]"
dnsRecord2=$(echo $allRecords | xpath $dnsRecordSearch 2>/dev/null)

# Check if we have both the records that have to be swapped
if ([ -z $dnsRecord1 ]) then
    echo "Could not find DNS record for $dnsEntryName1."
    exit 1
fi

if ([ -z $dnsRecord2 ]) then
    echo "Could not find DNS record for $dnsEntryName2."
    exit 1
fi

newRecord1=$(echo $dnsRecord1 | sed "s|<Name>$dnsEntryName1</Name>|<Name>$dnsEntryName2</Name>|g")
newRecord2=$(echo $dnsRecord2 | sed "s|<Name>$dnsEntryName2</Name>|<Name>$dnsEntryName1</Name>|g")

# Check if www prefix also has to be processed
if ([ ! -z $prefixName ]) then
    dnsRecord3=$(echo $dnsRecord1 | sed "s|<Name>$dnsEntryName1</Name>|<Name>www.$dnsEntryName1</Name>|g")
    dnsRecord4=$(echo $dnsRecord2 | sed "s|<Name>$dnsEntryName2</Name>|<Name>www.$dnsEntryName2</Name>|g")
    
    newRecord3=$(echo $dnsRecord3 | sed "s|<Name>www.$dnsEntryName1</Name>|<Name>www.$dnsEntryName2</Name>|g")
    newRecord4=$(echo $dnsRecord4 | sed "s|<Name>www.$dnsEntryName2</Name>|<Name>www.$dnsEntryName1</Name>|g")
    
    dnsRecord3=$(echo "<Change><Action>DELETE</Action>$dnsRecord3</Change>")
    dnsRecord4=$(echo "<Change><Action>DELETE</Action>$dnsRecord4</Change>")

    newRecord3=$(echo "<Change><Action>CREATE</Action>$newRecord3</Change>")
    newRecord4=$(echo "<Change><Action>CREATE</Action>$newRecord4</Change>")
fi


# Generate a timestamp to mark the Route53 transaction
timestamp=$(date)

# Create a temporary XML file
xmlTmp=$(mktemp)

# Set up the xml with delete and create commands
echo "Swapping the DNS records of $dnsEntryName1 and $dnsEntryName2"
cat <<ROUTE53-XML > $xmlTmp
<?xml version="1.0" encoding="UTF-8"?>
<ChangeResourceRecordSetsRequest xmlns="$urlRoute53APIDoc">
    <ChangeBatch>
        <Comment>Update Record for $dnsEntryName at $timestamp</Comment>
        <Changes>
            <Change>
                <Action>DELETE</Action>
                $dnsRecord1
            </Change>
            <Change>
                <Action>DELETE</Action>
                $dnsRecord2
            </Change>
            $dnsRecord3
            $dnsRecord4
            <Change>
                <Action>CREATE</Action>
                $newRecord1
            </Change>
            <Change>
                <Action>CREATE</Action>
                $newRecord2
            </Change>
            $newRecord3
            $newRecord4
        </Changes>
    </ChangeBatch>
</ChangeResourceRecordSetsRequest>
ROUTE53-XML

# POST the XML containing Route53 actions
route53Response=$(dnscurl.pl --keyname $awsAccountKeyName $optionsDNSCurl -X POST --upload-file $xmlTmp $urlRoute53API/hostedzone/$hostedZoneId/rrset 2>/dev/null)

# Delete the temporary XML file
rm -f $xmlTmp

# Obtain the response and check its status
route53ResponseStatus=$(echo $route53Response | xpath 'ChangeResourceRecordSetsResponse/ChangeInfo/Status' 2>/dev/null | awk -F'[<|>]' '/Status/{print $3}' | cut -d/ -f3)
if ([ "$route53ResponseStatus" != "PENDING" ]) then
    echo "Error: Expected PENDING status from Route53, but received some other status."
    echo $route53Response
    exit 1
fi

# Obtain Route53 transaction ID
route53ResponseID=$(echo $route53Response | xpath 'ChangeResourceRecordSetsResponse/ChangeInfo/Id' 2>/dev/null | awk -F'[<|>]' '/Id/{print $3}' | cut -d/ -f3)
echo "Received response status ID $route53ResponseID with status $route53ResponseStatus"

echo "Successfully swapped Route53 DNS records."
