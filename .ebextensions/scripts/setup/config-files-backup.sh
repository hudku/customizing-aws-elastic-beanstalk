#!/bin/bash


# Execute "export DEBUG=1" to debug this script.
# Set value to 2 to debug this script and the scripts called within this script.
# Set value to 3,4,5 and so on to increase the nesting level of the scripts to be debugged.
[[ $DEBUG -gt 0 ]] && set -x; export DEBUG=$(($DEBUG - 1))


#
# Backup all the configuration files that might be overwritten
#


# Backup original configuration files. It should be done only once and not during every deployment
if ([ ! -e /etc/httpd/conf.d/elasticbeanstalk.conf.bak ]) then
    cp /etc/httpd/conf.d/elasticbeanstalk.conf /etc/httpd/conf.d/elasticbeanstalk.conf.bak
    
    # mv /etc/my.cnf /etc/my.cnf.bak
    
    # cp /tmp/deployment/config/tomcat7 /tmp/deployment/config/tomcat7.bak
fi
