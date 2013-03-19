#!/bin/bash


# Execute "export DEBUG=1" to debug this script.
# Set value to 2 to debug this script and the scripts called within this script.
# Set value to 3,4,5 and so on to increase the nesting level of the scripts to be debugged.
[[ $DEBUG -gt 0 ]] && set -x; export DEBUG=$(($DEBUG - 1))

#
# Creates a new Elastic Beanstalk Development environment
#


fileDevelopmentConfig=$ELASTICBEANSTALK_APP_TMP_DIR/beanstalk-development-configuration.txt

# Alter the beanstalk configuration file and set the values required for development environment
cat $ELASTICBEANSTALK_APP_DATA_DIR/beanstalk-configuration.txt | sed 's/"Value": "m1.large"/"Value": "t1.micro"/' > $fileDevelopmentConfig

$ELASTICBEANSTALK_APP_SCRIPT_DIR/deployment/staging-create.sh $fileDevelopmentConfig
