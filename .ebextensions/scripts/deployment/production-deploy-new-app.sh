#!/bin/bash


# Execute "export DEBUG=1" to debug this script.
# Set value to 2 to debug this script and the scripts called within this script.
# Set value to 3,4,5 and so on to increase the nesting level of the scripts to be debugged.
[[ $DEBUG -gt 0 ]] && set -x; export DEBUG=$(($DEBUG - 1))


#
# Deploys a new version of the application to the Elastic Beanstalk Production environment
#


# include all the utility scripts
source $ELASTICBEANSTALK_APP_SCRIPT_DIR/include/include.sh


if ([ ! -z "$TOMCAT_SECONDARY_INSTANCE_NAME" ]) then
    if ( ! $(isPortOpen 8109) ) then
        echo "Warning: Port 8109 is NOT open and tomcat secondary instance has not been started."
        answer=$(promptDefaultNo)
        if ([ "$answer" == "n" ]) then
            exit 3
        fi
    fi
fi



$ELASTICBEANSTALK_APP_SCRIPT_DIR/deployment/staging-deploy-new-app.sh $ROUTE53_RR_PRODUCTION_NAME
