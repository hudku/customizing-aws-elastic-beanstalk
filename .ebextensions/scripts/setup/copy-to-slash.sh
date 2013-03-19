#!/bin/bash


# Execute "export DEBUG=1" to debug this script.
# Set value to 2 to debug this script and the scripts called within this script.
# Set value to 3,4,5 and so on to increase the nesting level of the scripts to be debugged.
[[ $DEBUG -gt 0 ]] && set -x; export DEBUG=$(($DEBUG - 1))


#
# Copy contents of "copy-to-slash" folder to "/" after setting required permissions
#


# Set permissions for all files in the root folder
if ([ -e $ELASTICBEANSTALK_APP_DIR/.ebextensions/copy-to-slash/root ]) then
	chmod -R 600 $ELASTICBEANSTALK_APP_DIR/.ebextensions/copy-to-slash/root
	chmod 644 $ELASTICBEANSTALK_APP_DIR/.ebextensions/copy-to-slash/root/.bashrc
	chmod 644 $ELASTICBEANSTALK_APP_DIR/.ebextensions/copy-to-slash/root/env.sh
fi

# Set permissions for all files in the etc folder
if ([ -e $ELASTICBEANSTALK_APP_DIR/.ebextensions/copy-to-slash/etc ]) then
	chmod -R 644 $ELASTICBEANSTALK_APP_DIR/.ebextensions/copy-to-slash/etc
	chmod -R 755 $ELASTICBEANSTALK_APP_DIR/.ebextensions/copy-to-slash/etc/cron.hourly
fi


# Copy the directories which could overwrite some existing files with our version 
/bin/cp -f -R $ELASTICBEANSTALK_APP_DIR/.ebextensions/copy-to-slash/* /
