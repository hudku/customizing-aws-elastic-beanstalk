#!/bin/bash


# Execute "export DEBUG=1" to debug this script.
# Set value to 2 to debug this script and the scripts called within this script.
# Set value to 3,4,5 and so on to increase the nesting level of the scripts to be debugged.
[[ $DEBUG -gt 0 ]] && set -x; export DEBUG=$(($DEBUG - 1))


#
# Setup AWS credentials so that all AWS command line utilities can work
#


# Obtain the AWS credentials from beanstalk tomcat configuration file
if ([ -f /tmp/deployment/config/tomcat7 ]) then
    AWS_ACCESS_KEY=$(grep -o "DAWS_ACCESS_KEY_ID=[^ ]*" /tmp/deployment/config/tomcat7 | cut -d'"' -f2 | cut -d '\' -f1)
    AWS_SECRET_KEY=$(grep -o "DAWS_SECRET_KEY=[^ ]*" /tmp/deployment/config/tomcat7 | cut -d'"' -f2 | cut -d '\' -f1)
fi


# Update all the appropriate files with AWS credentials so that we can start using all AWS command line utilities  
sed -i -e "s/AWSAccessKeyId=.*/AWSAccessKeyId=$AWS_ACCESS_KEY/" -e "s/AWSSecretKey=.*/AWSSecretKey=$AWS_SECRET_KEY/" /root/.aws-credentials
sed -i -e "s/id\s*=>.*/id => \"$AWS_ACCESS_KEY\",/" -e "s/key\s*=>.*/key => \"$AWS_SECRET_KEY\",/" -e "s/myAppName/$ELASTICBEANSTALK_APP_NAME/" /root/.aws-secrets
sed -i -e "s/access_key.*/access_key = $AWS_ACCESS_KEY/" -e "s/secret_key.*/secret_key = $AWS_SECRET_KEY/" /root/.s3cfg


# Obtain the secrets zip file from S3 containing passwords and other confidential information
if ([ ! -z $ELASTICBEANSTALK_APP_PRIVATE_S3_BUCKET ] && [ ! -z $ELASTICBEANSTALK_APP_DEPLOY_DIR ]) then
    
    if ([ ! -e ~/secrets/secrets.zip ]) then
        
        if ([ $(s3cmd --config=/root/.s3cfg ls s3://$ELASTICBEANSTALK_APP_PRIVATE_S3_BUCKET/$ELASTICBEANSTALK_APP_DEPLOY_DIR/secrets/ | grep "secrets.zip" | wc -l) -gt 0 ]) then
        
            mkdir -p ~/secrets
        
            # As AWS credentials are setup, access S3 and obtain some more secured and confidential information
            pushd ~/secrets
            s3cmd --config=/root/.s3cfg get s3://$ELASTICBEANSTALK_APP_PRIVATE_S3_BUCKET/$ELASTICBEANSTALK_APP_DEPLOY_DIR/secrets/secrets.zip
            popd
        
            chmod -R 400 ~/secrets/
        
        fi
    fi
    
    # Unzip the contents of the secrets zip file and overwrite any existing files
    if ([ -f ~/secrets/secrets.zip ]) then
        unzip -q -o ~/secrets/secrets.zip -d /
    fi
    
fi
