#!/bin/bash


# Execute "export DEBUG=1" to debug this script.
# Set value to 2 to debug this script and the scripts called within this script.
# Set value to 3,4,5 and so on to increase the nesting level of the scripts to be debugged.
[[ $DEBUG -gt 0 ]] && set -x; export DEBUG=$(($DEBUG - 1))

#
# Rotate the log files immediately. Useful to call this and backup log files, if the environment is about to be terminated.
#


# Run the daily logrotate scripts. We rotate logs on daily basis and not every hour.
if [ -f /etc/cron.daily/logrotate-elasticbeanstalk ]; then
    bash /etc/cron.daily/logrotate-elasticbeanstalk
fi

if [ -f /etc/cron.daily/logrotate-elasticbeanstalk-httpd ]; then
    bash /etc/cron.daily/logrotate-elasticbeanstalk-httpd
fi
