#!/bin/bash


# Execute "export DEBUG=1" to debug this script.
# Set value to 2 to debug this script and the scripts called within this script.
# Set value to 3,4,5 and so on to increase the nesting level of the scripts to be debugged.
[[ $DEBUG -gt 0 ]] && set -x; export DEBUG=$(($DEBUG - 1))


#
# Swaps Route53 DNS records of production and staging Elastic Beanstalk environments
#


dnsProduction=$($ELASTICBEANSTALK_APP_SCRIPT_DIR/util/route53-get-alias-target-dns.sh $ROUTE53_RR_PRODUCTION_NAME)
dnsStaging=$($ELASTICBEANSTALK_APP_SCRIPT_DIR/util/route53-get-alias-target-dns.sh $ROUTE53_RR_STAGING_NAME)

envNameProduction=$($ELASTICBEANSTALK_APP_SCRIPT_DIR/util/elastic-beanstalk-get-env-name-from-elb-url.sh $dnsProduction)
envNameStaging=$($ELASTICBEANSTALK_APP_SCRIPT_DIR/util/elastic-beanstalk-get-env-name-from-elb-url.sh $dnsStaging)

# Swap Production and Staging Route53 records
$ELASTICBEANSTALK_APP_SCRIPT_DIR/util/route53-swap-dns-records.sh $AWS_ACCOUNT_KEY_NAME $ROUTE53_RR_PRODUCTION_NAME $ROUTE53_RR_STAGING_NAME

# Swap Route53 EC2 CNAME records
$ELASTICBEANSTALK_APP_SCRIPT_DIR/util/route53-swap-dns-records.sh $AWS_ACCOUNT_KEY_NAME ec2.$ROUTE53_RR_PRODUCTION_NAME ec2.$ROUTE53_RR_STAGING_NAME


# Swap Elastic Beanstalk CNAME records
echo "Swapping Elastic Beanstalk environment URLs of production $envNameProduction and staging $envNameStaging"
elastic-beanstalk-swap-environment-cnames -s $envNameProduction -d $envNameStaging
