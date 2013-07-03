#!/bin/bash


# Execute "export DEBUG=1" to debug this script.
# Set value to 2 to debug this script and the scripts called within this script.
# Set value to 3,4,5 and so on to increase the nesting level of the scripts to be debugged.
[[ $DEBUG -gt 0 ]] && set -x; export DEBUG=$(($DEBUG - 1))


#
# Terminates the Elastic Beanstalk Staging environment
#


# include all the utility scripts
source $ELASTICBEANSTALK_APP_SCRIPT_DIR/include/include.sh


display_usage()
{
    echo -e "\nUsage: $0 [route53_RR_Name]\n"
}

# Exactly one argument should be supplied
if ([ $# -gt 1 ]) then
    display_usage
    exit 2
fi


# Terminate staging entry unless another entry is supplied
stagingDNSEntryName=$ROUTE53_RR_STAGING_NAME
if ([ ! -z $1 ]) then
    stagingDNSEntryName=$1
fi


# Delete www entry also
#prefixName="www"

awsAccountKeyName=$AWS_ACCOUNT_KEY_NAME

dnsEntryName=$stagingDNSEntryName


# extract host name from the dns entry name
hostName=$(echo $dnsEntryName | grep -o "[^\.]*\.[^\.]*\.$")


# Route53 API settings
urlRoute53API="https://route53.amazonaws.com/2012-12-12"
urlRoute53APIDoc="https://route53.amazonaws.com/doc/2012-12-12/"


# Get Route53 HostedZoneId
allHostedZones=$(dnscurl.pl --keyname $awsAccountKeyName -- -s -H "Content-Type: text/xml; charset=UTF-8" -X GET $urlRoute53API/hostedzone 2>/dev/null)
hostNameSearch="ListHostedZonesResponse/HostedZones/HostedZone[Name=\"$hostName\"]/Id"
hostedZoneId=$(echo $allHostedZones | xpath $hostNameSearch 2>/dev/null | awk -F'[<|>]' '/Id/{print $3}' | cut -d/ -f3)
if ([ -z $hostedZoneId ]) then
    echo "Error: Failed to obtain hosted zone id for '$hostName' in Route53"
    exit 1
fi

# Obtain all the resource record sets for the hosted zone id
allRecords=$(dnscurl.pl --keyname $awsAccountKeyName -- -s -H "Content-Type: text/xml; charset=UTF-8" -X GET $urlRoute53API/hostedzone/$hostedZoneId/rrset 2>/dev/null)

# Obtain the DNS record
dnsRecordSearch="ListResourceRecordSetsResponse/ResourceRecordSets/ResourceRecordSet[Name=\"$dnsEntryName\"]"
dnsRecord=$(echo $allRecords | xpath $dnsRecordSearch 2>/dev/null)
if ([ -z $dnsRecord ]) then
    echo "Error: Failed to obtain DNS Record from Route53. HostedZoneId: '$hostName' DNSEntryName: '$dnsEntryName'"
    exit 1
fi


# Get ec2 CNAME record
dnsEC2RecordSearch="ListResourceRecordSetsResponse/ResourceRecordSets/ResourceRecordSet[Name=\"ec2.$dnsEntryName\"]"
dnsEC2Record=$(echo $allRecords | xpath $dnsEC2RecordSearch 2>/dev/null)

# Obtain elb URL of the staging environment
dnsNameSearch="ListResourceRecordSetsResponse/ResourceRecordSets/ResourceRecordSet[Name=\"$dnsEntryName\"]/AliasTarget/DNSName"
dnsName=$(echo $allRecords | xpath $dnsNameSearch 2>/dev/null | awk -F'[<|>]' '/DNSName/{print $3}' | cut -d/ -f3 | sed 's/.$//')

# Using the elb URL obtain the beanstalk environment name
envName=$(elastic-beanstalk-describe-environments -j | grep -io "\"EndpointURL\":\"$dnsName\",\"EnvironmentId\":\"[^\"]*\",\"EnvironmentName\":\"[^\"]*\"" | cut -d, -f3 | cut -d: -f2 | sed s/\"//g)

# Check envName format
testEnvName=$(echo $envName | grep "^env-[0-9]\{8\}-[0-9]\{4\}$")
if ([ -z $testEnvName ]) then
    echo "Environment Name is '$envName' whose format is unknown. Not trying to terminate the environment."
    exit 1
fi


# Just check to ensure that we are not trying to terminate the production environment
ipProduction=$(getIPOfURL "$ROUTE53_RR_PRODUCTION_NAME")
ipCurELB=$(getIPOfURL "$dnsName")
if ([ ! -z "$ipProduction" ] && [ ! -z "$ipCurELB" ]) then
    if ([ "$ipProduction" == "$ipCurELB" ]) then
        echo "Error: Attempt to terminate the production environment running at $ROUTE53_RR_PRODUCTION_NAME."
        exit 1
    fi
fi  


echo "Terminating the environment $envName"
elastic-beanstalk-terminate-environment -e $envName


if ([ ! -z $dnsRecord ]) then
    dnsRecord=$(echo "<Change><Action>DELETE</Action>$dnsRecord</Change>")
fi

if ([ ! -z $dnsEC2Record ]) then
	dnsEC2Record=$(echo "<Change><Action>DELETE</Action>$dnsEC2Record</Change>")
fi

# check if www prefix also has to be processed
if ([ ! -z $prefixName ]) then
	if ([ ! -z $dnsRecord ]) then
        dnsPrefixRecord=$(echo $dnsRecord | sed "s|<Name>$dnsEntryName</Name>|<Name>www.$dnsEntryName</Name>|g")
    fi
fi


# Generate a timestamp to mark the Route53 transaction
timestamp=$(date)

# Create a temporary XML file
xmlTmp=$(mktemp)

# Set up the xml to delete the DNS entries
echo "Deleting Alias records of $dnsEntryName"
cat <<ROUTE53-XML > $xmlTmp
<?xml version="1.0" encoding="UTF-8"?>
<ChangeResourceRecordSetsRequest xmlns="$urlRoute53APIDoc">
    <ChangeBatch>
        <Comment>Deleting Record for $dnsEntryName at $timestamp</Comment>
        <Changes>
            $dnsRecord
            $dnsPrefixRecord
            $dnsEC2Record
        </Changes>
    </ChangeBatch>
</ChangeResourceRecordSetsRequest>
ROUTE53-XML

# POST the XML containing Route53 actions
route53Response=$(dnscurl.pl --keyname $awsAccountKeyName -- -s -H "Content-Type: text/xml; charset=UTF-8" -X POST --upload-file $xmlTmp $urlRoute53API/hostedzone/$hostedZoneId/rrset 2>/dev/null)

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

echo "Successfully removed Route53 records."
