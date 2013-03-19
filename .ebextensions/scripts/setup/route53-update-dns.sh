#!/bin/bash


# Execute "export DEBUG=1" to debug this script.
# Set value to 2 to debug this script and the scripts called within this script.
# Set value to 3,4,5 and so on to increase the nesting level of the scripts to be debugged.
[[ $DEBUG -gt 0 ]] && set -x; export DEBUG=$(($DEBUG - 1))


#
# Update Route53 DNS records for current EC2 instance
#


# include all the utility scripts
source $ELASTICBEANSTALK_APP_SCRIPT_DIR/include/include.sh



# If we are a production machine then do nothing as DNS records should already be in place
ipProduction=$(getIPOfURL "$ROUTE53_RR_PRODUCTION_NAME")
ipCurELB=$(getIPOfURL "$ELB_URL")
if [ ! -z "$ipProduction" ] && [ ! -z "$ipCurELB" ]; then
    if [ "$ipProduction" == "$ipCurELB" ]; then
        exit 0
    fi
fi  


envName=$ELASTICBEANSTALK_ENV_NAME

# Check envName format
testEnvName=$(echo $envName | grep "^env-[0-9]\{8\}-[0-9]\{4\}$")
if [ -z "$testEnvName" ]; then
    echo "Error: Environment Name is '$envName' whose format is unknown. DNS records are not updated."
    exit 1
fi


route53RRName=$ROUTE53_RR_STAGING_NAME
if [ "$EC2_INSTANCE_TYPE" == "t1.micro" ]; then
    route53RRName=$ROUTE53_RR_DEVELOPMENT_NAME
fi

if [ -z "$route53RRName" ]; then
    echo "Error: Route53 Resource Record Name is not provided. DNS records are not updated."
    exit 1
fi

route53HostedZoneID=$ROUTE53_ZONE_ID

elbURL=$ELB_URL
elbHostedZoneId=$ELB_HOSTEDZONE_ID


# If development environment swap the elasticbeanstalk URLs if necessary
if [ "$route53RRName" == "$ROUTE53_RR_DEVELOPMENT_NAME" ]; then
    
    ipPrevDevelopment=$(getIPOfURL "$route53RRName")
    if [ ! -z "$ipPrevDevelopment" ] && [ ! -z "$ipCurELB" ]; then
        if [ "$ipPrevDevelopment" != "$ipCurELB" ]; then
            
            elbURLPrevDevelopment=$($ELASTICBEANSTALK_APP_SCRIPT_DIR/util/elb-get-url-from-ip.sh $ipPrevDevelopment) 
            envNamePrevDevelopment=$($ELASTICBEANSTALK_APP_SCRIPT_DIR/util/elastic-beanstalk-get-env-name-from-elb-url.sh $elbURLPrevDevelopment)
            
            # Swap Elastic Beanstalk CNAME records after some minutes by which time environment creation would have been completed
            echo "Swapping Elastic Beanstalk development environment URLs $envName and $envNamePrevDevelopment"
            elastic-beanstalk-swap-environment-cnames -s $envNamePrevDevelopment -d $envName | at now + 32 minutes
             
        fi
    fi  
fi



ipCur=$(getIPOfURL "$route53RRName")

# Update DNS records only if necessary
if [ -z "$ipCur" ] || [ -z "$ipCurELB" ] || [ "$ipCur" != "$ipCurELB" ]; then
    
    # Update AliasTarget record to point to the Load Balancer
    aliasTargetRecord=$(route53 get $route53HostedZoneID | grep -i "^$route53RRName")
    if [ -z "$aliasTargetRecord" ]; then
        # Add the new ALIAS record
        route53 add_alias $route53HostedZoneID $route53RRName A $elbHostedZoneId $elbURL
    else
        # Change existing ALIAS record
        route53 change_alias $route53HostedZoneID $route53RRName A $elbHostedZoneId $elbURL
    fi
	
    # Update EC2 CNAME record
    cnameRecord=$(route53 get $route53HostedZoneID | grep -i "^ec2.$route53RRName")
    if [ -z "$cnameRecord" ]; then
        # Add the new CNAME record
        route53 add_record $route53HostedZoneID ec2.$route53RRName CNAME "$EC2_INSTANCE_URL" 300
    else
        # Change existing CNAME record
        route53 change_record $route53HostedZoneID ec2.$route53RRName CNAME "$EC2_INSTANCE_URL" 300
    fi
        
fi
