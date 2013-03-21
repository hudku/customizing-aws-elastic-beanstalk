#!/bin/bash


# Execute "export DEBUG=1" to debug this script.
# Set value to 2 to debug this script and the scripts called within this script.
# Set value to 3,4,5 and so on to increase the nesting level of the scripts to be debugged.
[[ $DEBUG -gt 0 ]] && set -x; export DEBUG=$(($DEBUG - 1))


#
# Creates a new Elastic Beanstalk Staging environment
#


# include all the utility scripts
source $ELASTICBEANSTALK_APP_SCRIPT_DIR/include/include.sh


display_usage()
{
    echo -e "\nUsage: $0 [beanstalk-config-file-name]\n"
}

# Check the argument count
if ([ $# -gt 1 ]) then
    display_usage
    exit 2
fi


# Use the default config file and CNAME if not supplied
fileBeanstalkConfig=$ELASTICBEANSTALK_APP_DATA_DIR/beanstalk-configuration.txt
envCNAME="${ELASTICBEANSTALK_APP_NAME}_staging"

# If parameter is supplied then alter the default values
if ([ ! -z "$1" ]) then
    fileBeanstalkConfig=$1
    envCNAME="${ELASTICBEANSTALK_APP_NAME}-dev"
fi

# Check if the beanstalk configuration file exists
if ([ ! -f $fileBeanstalkConfig ]) then
    echo "Error: Beanstalk configuration file $fileBeanstalkConfig does not exist."
    exit 1
fi


warFileDirInPrivateBucket=$ELASTICBEANSTALK_APP_PRIVATE_S3_BUCKET/$ELASTICBEANSTALK_APP_DEPLOY_DIR/war

if ([ $(s3cmd ls s3://$warFileDirInPrivateBucket/ | grep "\.war" | wc -l) -gt 1 ]) then
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

# Get the UTC datetime of war file
warFileDateTime=$(echo ${warFileInfo} | awk '{print $1," ",$2}')

# Convert datetime in UTC to IST which is what gets displayed in our S3 console
warFileDateTime=$(date +'%Y%m%d-%H%M' -d "${warFileDateTime} -05:30")


# Use the current datetime to be used in the environment name
envDateTime=$(date +'%Y-%m-%d %H:%M')
envDateTime=$(date +'%Y%m%d-%H%M' -d "${envDateTime} -05:30")


filename=$(basename "$warFileName")
extension="${filename##*.}"
filename="${filename%.*}"

# Make version name using file name and datetime
appNewVersionFileName="${filename}-${warFileDateTime}.${extension}"

# Check if the application version has already been created
lblAppNewVersion=$(elastic-beanstalk-describe-application-versions -l lbl_${appNewVersionFileName} | grep -o lbl_${appNewVersionFileName})
if ([ ! -z "$lblAppNewVersion" ]) then

    # Check if this war file is already deployed in some environment
    existingURL=$($ELASTICBEANSTALK_APP_SCRIPT_DIR/util/elastic-beanstalk-get-elb-url-from-app-version.sh $lblAppNewVersion)
    if ([ ! -z "$existingURL" ]) then
        echo "WARNING: The war file ${warFileName} is already deployed at URL $existingURL"
        answer=$(promptDefaultNo)
        if ([ "$answer" == "n" ]) then
            exit 3
        fi
    fi
    
fi



# If the application version does not exist then copy the war file and create a new application version
if ([ -z "$lblAppNewVersion" ]) then
    # Copy war file to beanstalk bucket
    s3cmd --config=/root/.s3cfg cp s3://$warFileDirInPrivateBucket/$warFileName s3://${ELASTICBEANSTALK_S3_BUCKET}/$appNewVersionFileName

    # Create the application version from the copied war file
    elastic-beanstalk-create-application-version -a $ELASTICBEANSTALK_APP_NAME -l lbl_${appNewVersionFileName} -d desc_${appNewVersionFileName} -s ${ELASTICBEANSTALK_S3_BUCKET}/${appNewVersionFileName}
fi


# Try to supply CNAME to Beanstalk while creating the new environment
sCNAMEOption="-c $envCNAME"

# If CNAME is already in use then we cannot use it
ipCNAME=$(getIPOfURL "$envCNAME.elasticbeanstalk.com")
if ([ ! -z "$ipCNAME" ]) then
    sCNAMEOption=""
fi

# Launch the new environment
elastic-beanstalk-create-environment -a $ELASTICBEANSTALK_APP_NAME -l lbl_${appNewVersionFileName} -e env-${envDateTime} -s "64bit Amazon Linux running Tomcat 7" -f $fileBeanstalkConfig $sCNAMEOption
