#!/bin/bash


# Execute "export DEBUG=1" to debug this script.
# Set value to 2 to debug this script and the scripts called within this script.
# Set value to 3,4,5 and so on to increase the nesting level of the scripts to be debugged.
[[ $DEBUG -gt 0 ]] && set -x; export DEBUG=$(($DEBUG - 1))


#
# Setup logging
#


# include all the utility scripts
source $ELASTICBEANSTALK_APP_SCRIPT_DIR/include/include.sh



# Make the log rotation happen daily instead of hourly
#if $(exists /etc/cron.hourly/logrotate-elasticbeanstalk*) ; then
    # mv /etc/cron.hourly/logrotate-elasticbeanstalk* /etc/cron.daily/
    # sed -i 's|/usr/sbin/logrotate /etc/logrotate.conf.elasticbeanstalk.httpd|/usr/sbin/logrotate -f /etc/logrotate.conf.elasticbeanstalk.httpd|g' /etc/cron.daily/logrotate-elasticbeanstalk-httpd
#fi

