#!/bin/bash


# Execute "export DEBUG=1" to debug this script.
# Set value to 2 to debug this script and the scripts called within this script.
# Set value to 3,4,5 and so on to increase the nesting level of the scripts to be debugged.
[[ $DEBUG -gt 0 ]] && set -x; export DEBUG=$(($DEBUG - 1))


#
# Terminates the development environment
#


$ELASTICBEANSTALK_APP_SCRIPT_DIR/deployment/staging-terminate.sh $ROUTE53_RR_DEVELOPMENT_NAME
