#!/bin/bash


# Execute "export DEBUG=1" to debug this script.
# Set value to 2 to debug this script and the scripts called within this script.
# Set value to 3,4,5 and so on to increase the nesting level of the scripts to be debugged.
[[ $DEBUG -gt 0 ]] && set -x; export DEBUG=$(($DEBUG - 1))

#
# Deploys a new version of the application to the Elastic Beanstalk Staging environment
#


# include all the utility scripts
source $ELASTICBEANSTALK_APP_SCRIPT_DIR/include/include.sh


display_usage()
{
    echo -e "\nUsage: $0 route53_RR_Name\n"
}

# Check argument count
if ([ $# -gt 1 ]) then
    display_usage
    exit 2
fi


# Deploy new app to staging entry unless another entry is supplied
route53RRName=$ROUTE53_RR_STAGING_NAME
if ([ ! -z $1 ]) then
    route53RRName=$1
fi


# Extract host name from the dns entry name
hostName=$(echo $route53RRName | grep -o "[^\.]*\.[^\.]*\.$")

# Get Route53 hosted zone ID
route53HostedZoneID=$(route53 ls | sed -n -e '/'"$hostName"'/{g;1!p;};h' | awk '{print $3}')
if ([ -z "$route53HostedZoneID" ]) then
    echo "Could not find zone '$hostName' in Route53"
    exit 1
fi

# Retrieve the AliasTarget record
aliasTargetRecord=$(route53 get $route53HostedZoneID | grep -i "^$route53RRName" | grep "ALIAS")
if ([ -z "$aliasTargetRecord" ]) then
    echo "Could not obtain AliasTarget record for '$route53RRName' in Route53"
    exit 1
fi

# Extract Load Balancer URL from AliasTarget record
elbURL=$(echo $aliasTargetRecord | awk '{print $6}')
if ([ -z "$elbURL" ]) then
    echo "Error: Could not obtain elbURL from AliasTarget record $aliasTargetRecord of $route53RRName"
    exit 1
fi

# Obtain the environment name using the Load Balancer URL
envName=$($ELASTICBEANSTALK_APP_SCRIPT_DIR/util/elastic-beanstalk-get-env-name-from-elb-url.sh $elbURL)
if ([ -z "$envName" ]) then
    echo "Error: Could not obtain environment name for $route53RRName and URL $elbURL"
    exit 1
fi

# Check envName format
testEnvName=$(echo $envName | grep "^env-[0-9]\{8\}-[0-9]\{4\}$")
if ([ -z "$testEnvName" ]) then
    echo "Environment Name is '$envName' whose format is unknown. Not trying to move the environment to staging"
    exit 1
fi


warFileDirInPrivateBucket=$ELASTICBEANSTALK_APP_PRIVATE_S3_BUCKET/$ELASTICBEANSTALK_APP_DEPLOY_DIR/war

if [ $(s3cmd ls s3://$warFileDirInPrivateBucket/ | grep "\.war" | wc -l) -gt 1 ]; then
    echo "Error: Found more than one war file in 's3://$warFileDirInPrivateBucket/'"
    echo -e "Files found are\n$(s3cmd ls s3://$warFileDirInPrivateBucket/ | grep "\.war")"
    exit 1
fi

warFileInfo=$(s3cmd ls s3://$warFileDirInPrivateBucket/ | grep "\.war")
if ([ -z "$warFileInfo" ]) then
    echo "Error: Could not find war files in 's3://$warFileDirInPrivateBucket/'"
    exit 1
fi

warFileName=$(echo ${warFileInfo} | awk '{print $4}' | sed "s|^s3:.*/||g")

filename=$(basename "$warFileName")
extension="${filename##*.}"
filename="${filename%.*}"


# Get the UTC datetime of war file
warFileDateTime=$(echo ${warFileInfo} | awk '{print $1," ",$2}')

# Convert datetime in UTC to IST which is what gets displayed in S3 console
warFileDateTime=$(date +'%Y%m%d-%H%M' -d "${warFileDateTime} -05:30")

appNewVersionFileName="${filename}-${warFileDateTime}.${extension}"

# Check if this war file is already deployed in the current environment
existingURL=$($ELASTICBEANSTALK_APP_SCRIPT_DIR/util/elastic-beanstalk-get-elb-url-from-app-version.sh lbl_$appNewVersionFileName)
if ([ ! -z "$existingURL" ]) then
    tmp=$(echo "$elbURL" | grep -i "^$existingURL$")
    if ([ ! -z "$tmp"  ]) then
        echo "ERROR: The war file ${warFileName} is already deployed in the current environment $envName"
        exit 1
    fi 
fi


# Copy war file and create an application version if it is not already present
if ([ -z "$existingURL" ]) then
    # Copy war file to beanstalk bucket
	s3cmd --config=/root/.s3cfg cp s3://$warFileDirInPrivateBucket/$warFileName s3://${ELASTICBEANSTALK_S3_BUCKET}/$appNewVersionFileName
	
    # Create the application version from the copied war file
	elastic-beanstalk-create-application-version -a $ELASTICBEANSTALK_APP_NAME -l lbl_${appNewVersionFileName} -d desc_${appNewVersionFileName} -s ${ELASTICBEANSTALK_S3_BUCKET}/${appNewVersionFileName}
fi


# Deploy the application to the beanstalk environment
elastic-beanstalk-update-environment -e $envName -l lbl_${appNewVersionFileName}


# Remove existing elastic beanstalk logs so that it is easier for us to troubleshoot
if ([ $? -eq 0 ]) then
    if ([ -f $ELASTICBEANSTALK_APP_SCRIPT_DIR/util/rm-eb-logs.sh ]) then
        $ELASTICBEANSTALK_APP_SCRIPT_DIR/util/rm-eb-logs.sh
    fi
fi
