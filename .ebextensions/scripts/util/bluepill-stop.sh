#!/bin/bash

# Execute "export DEBUG=1" to debug this script.
# Set value to 2 to debug this script and the scripts called within this script.
# Set value to 3,4,5 and so on to increase the nesting level of the scripts to be debugged.
[[ $DEBUG -gt 0 ]] && set -x; export DEBUG=$(($DEBUG - 1))


#
# Stops bluepill process used by Elastic Beanstalk so that it does not automatically start the primary Tomcat instance
#


pid_bluepill=$(ps -ef | grep "bluepilld: tomcat" | grep -v grep | awk '{print $2}')

if ([ ! -z $pid_bluepill ]) then
    kill $pid_bluepill
fi
