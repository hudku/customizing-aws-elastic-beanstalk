#!/bin/bash

# Execute "export DEBUG=1" to debug this script.
# Set value to 2 to debug this script and the scripts called within this script.
# Set value to 3,4,5 and so on to increase the nesting level of the scripts to be debugged.
[[ $DEBUG -gt 0 ]] && set -x; export DEBUG=$(($DEBUG - 1))


# Setup crontab jobs
if ([ -f $ELASTICBEANSTALK_APP_DATA_DIR/crontab.txt ]) then

    # Remove any existing entries and add new ones
    sudo crontab -l | grep -v "/$ELASTICBEANSTALK_APP_NAME/" | { cat; cat $ELASTICBEANSTALK_APP_DATA_DIR/crontab.txt; } | crontab -

fi
