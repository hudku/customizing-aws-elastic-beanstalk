#!/bin/bash

# Execute "export DEBUG=1" to debug this script.
# Set value to 2 to debug this script and the scripts called within this script.
# Set value to 3,4,5 and so on to increase the nesting level of the scripts to be debugged.
[[ $DEBUG -gt 0 ]] && set -x; export DEBUG=$(($DEBUG - 1))


# This file contains all the environment variables used by the scripts of elastic beanstalk application


# Displays error in case the file does not exist 
source /root/.elastic-beanstalk-app

# export all the variables sourced above from the app config file so that they are copied to the file env-result.sh

# Elasticbeanstalk app main settings
export ELASTICBEANSTALK_APP_NAME=$ELASTICBEANSTALK_APP_NAME
export ELASTICBEANSTALK_APP_PRIVATE_S3_BUCKET=$ELASTICBEANSTALK_APP_PRIVATE_S3_BUCKET
export ELASTICBEANSTALK_APP_DEPLOY_DIR=$ELASTICBEANSTALK_APP_DEPLOY_DIR


# Apache related
export APACHE_DIR=$APACHE_DIR

# Tomcat related
export TOMCAT_DIR=$TOMCAT_DIR
export TOMCAT_PRIMARY_INSTANCE_NAME=$TOMCAT_PRIMARY_INSTANCE_NAME
export TOMCAT_SECONDARY_INSTANCE_NAME=$TOMCAT_SECONDARY_INSTANCE_NAME

# AWS credentials settings
export AWS_CREDENTIAL_FILE=$AWS_CREDENTIAL_FILE
export AWS_ACCOUNT_KEY_NAME=$AWS_ACCOUNT_KEY_NAME

# RDS settings
export RDS_INSTANCE_NAME=$RDS_INSTANCE_NAME

# Route53 settings
export ROUTE53_ZONE_NAME=$ROUTE53_ZONE_NAME
export ROUTE53_RR_PRODUCTION_NAME=$ROUTE53_RR_PRODUCTION_NAME
export ROUTE53_RR_STAGING_NAME=$ROUTE53_RR_STAGING_NAME
export ROUTE53_RR_DEVELOPMENT_NAME=$ROUTE53_RR_DEVELOPMENT_NAME



# AWS Security Credentials
source $AWS_CREDENTIAL_FILE
export AWS_ACCESS_KEY=$AWSAccessKeyId
export AWS_SECRET_KEY=$AWSSecretKey



# Set up few derived environment variables of the app
export ELASTICBEANSTALK_APP_DIR="/$ELASTICBEANSTALK_APP_NAME"
export ELASTICBEANSTALK_APP_EXT_DIR="$ELASTICBEANSTALK_APP_DIR/.ebextensions"
export ELASTICBEANSTALK_APP_TMP_DIR="$ELASTICBEANSTALK_APP_DIR/tmp"

export ELASTICBEANSTALK_APP_DATA_DIR="$ELASTICBEANSTALK_APP_EXT_DIR/data"
export ELASTICBEANSTALK_APP_SCRIPT_DIR="$ELASTICBEANSTALK_APP_EXT_DIR/scripts"



# EC2 environment variables
EC2_ZONE=$(/opt/aws/bin/ec2-metadata -z | grep placement: | awk '{print $2}')

if ([ -f /etc/elasticbeanstalk/.aws-eb-stack.properties ]) then
    EC2_REGION=$(cat /etc/elasticbeanstalk/.aws-eb-stack.properties | grep "region=" | cut -d= -f2)
else
    EC2_REGION=$(curl -fs http://169.254.169.254/latest/dynamic/instance-identity/document | grep "\"region\"" | awk '{print $3}' | sed s/\"//g)
fi

EC2_URL=https://$(/opt/aws/bin/ec2-describe-regions $EC2_REGION | grep $EC2_REGION | awk '{print $3}')
EC2_INSTANCE_ID=$(/opt/aws/bin/ec2-metadata -i | grep instance-id: | awk '{print $2}')
EC2_INSTANCE_TYPE=$(/opt/aws/bin/ec2-metadata -t | grep instance-type: | awk '{print $2}')
EC2_INSTANCE_URL=$(/opt/aws/bin/ec2-metadata -p | grep public-hostname: | awk '{print $2}')
export EC2_REGION
export EC2_ZONE
export EC2_URL
export EC2_INSTANCE_ID
export EC2_INSTANCE_TYPE
export EC2_INSTANCE_URL


# AWS environment variables
AWS_REGION=$EC2_REGION
export AWS_REGION


# ELB environment variables
allRecords=$(/opt/aws/bin/elb-describe-lbs --show-xml)

# Setup XPath query to obtain the ELB record containing the current EC2_INSTANCE_ID
elbRecordSearch="DescribeLoadBalancersResponse/DescribeLoadBalancersResult/LoadBalancerDescriptions/member[ Instances/member/InstanceId = \"$EC2_INSTANCE_ID\" ]"

elbNameSearch="$elbRecordSearch/LoadBalancerName"
ELB_NAME=$(echo $allRecords | xpath "$elbNameSearch" 2> /dev/null | cut -d">" -f2 | cut -d"<" -f1)

elbHostedZoneNameSearch="$elbRecordSearch/CanonicalHostedZoneName"
ELB_HOSTEDZONE_NAME=$(echo $allRecords | xpath "$elbHostedZoneNameSearch" 2> /dev/null | cut -d">" -f2 | cut -d"<" -f1)

elbHostedZoneIdSearch="$elbRecordSearch/CanonicalHostedZoneNameID"
ELB_HOSTEDZONE_ID=$(echo $allRecords | xpath "$elbHostedZoneIdSearch" 2> /dev/null | cut -d">" -f2 | cut -d"<" -f1)

elbDNSNameSearch="$elbRecordSearch/DNSName"
ELB_URL=$(echo $allRecords | xpath "$elbDNSNameSearch" 2> /dev/null | cut -d">" -f2 | cut -d"<" -f1)

export ELB_NAME
export ELB_HOSTEDZONE_NAME
export ELB_HOSTEDZONE_ID
export ELB_URL


# ELASTICBEANSTALK environment variables
if ([ -f /root/.elastic-beanstalk-cmd-leader ]) then
    source /root/.elastic-beanstalk-cmd-leader
fi
export ELASTICBEANSTALK_CMD_LEADER=$ELASTICBEANSTALK_CMD_LEADER

if ([ -f /etc/elasticbeanstalk/.aws-eb-stack.properties ]) then
	ELASTICBEANSTALK_URL=$(echo $EC2_URL | sed s/ec2\./elasticbeanstalk./)
	ELASTICBEANSTALK_S3_BUCKET=$(cat /etc/elasticbeanstalk/.aws-eb-stack.properties | grep "environment_bucket=" | cut -d= -f2)
	ELASTICBEANSTALK_ENV_ID=$(cat /etc/elasticbeanstalk/.aws-eb-stack.properties | grep "environment_id=" | cut -d= -f2)
	ELASTICBEANSTALK_ENV_NAME=$(/opt/aws/bin/ec2-describe-instances $EC2_INSTANCE_ID | grep "elasticbeanstalk:environment-name" | awk '{print $5}')

    envInfo=$(elastic-beanstalk-describe-environments -e $ELASTICBEANSTALK_ENV_NAME -j)
    ELASTICBEANSTALK_CNAME=$(echo -e "$envInfo" | grep -ioP "CNAME\":.*?elasticbeanstalk\.com\"" | cut -d, -f1 | cut -d: -f2 | sed s/\"//g)
fi
export ELASTICBEANSTALK_URL
export ELASTICBEANSTALK_S3_BUCKET
export ELASTICBEANSTALK_ENV_ID
export ELASTICBEANSTALK_ENV_NAME
export ELASTICBEANSTALK_CNAME


# ROUTE53 environment variables
export ROUTE53_ZONE_ID=$(route53 ls | sed -n -e '/'"$ROUTE53_ZONE_NAME"'/{g;1!p;};h' | awk '{print $3}')


# MYSQL environment variables
if ([ -f /etc/my.cnf ]) then
    MYSQL_USER=$(cat /etc/my.cnf | grep "user=" | cut -d= -f2)
    MYSQL_PASSWORD=$(cat /etc/my.cnf | grep "password=" | cut -d= -f2)
fi
export MYSQL_USER
export MYSQL_PASSWORD


# GIT credentials in case provided in the file .elastic-beanstalk-app
export GIT_USER_NAME="$GIT_USER_NAME"
export GIT_PASSWORD="$GIT_PASSWORD"



# Generate envResult.sh using the settings from 'this' file
envResult=$(cat /root/env.sh | grep -o "^[ \t]*export[ \t]*[^=]*" | sed "s/export[ \t]*\(.*\)$/export \\1=\\\\\"$\\1\\\\\"/")
envResult=$(echo $envResult | sed "s/ export/\\\\nexport/g")
envResult="echo -e \"$envResult\""

# By copying we get the same file permissions of env.sh to env-result.sh
cp -f ~/env.sh ~/env-result.sh
echo -e "# This file is generated by running ~/env.sh and contains all export statements with values.\n" > ~/env-result.sh
eval $envResult >>  ~/env-result.sh
