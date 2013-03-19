#!/bin/bash

# Execute "export DEBUG=1" to debug this script.
# Set value to 2 to debug this script and the scripts called within this script.
# Set value to 3,4,5 and so on to increase the nesting level of the scripts to be debugged.
[[ $DEBUG -gt 0 ]] && set -x; export DEBUG=$(($DEBUG - 1))


appName=$ELASTICBEANSTALK_APP_NAME


#
# You can do all custom tasks here or you can call other scripts.
#


# Check if this is the very first time this script is running by checking the presence of a file
if ([ ! -f /root/.not-a-new-instance.txt ]) then
    newEC2Instance=true
fi



if ([ $newEC2Instance ]) then
    
    # If new instance then perform tasks such as installing a package or download files/folders from S3 private bucket
    if ([ -f $ELASTICBEANSTALK_APP_SCRIPT_DIR/$appName-setup/$appName-package-install.sh ]) then
        $ELASTICBEANSTALK_APP_SCRIPT_DIR/$appName-setup/$appName-package-install.sh
    fi

fi


# Commands to be executed only by the leader of AutoScaling group
if ([ $ELASTICBEANSTALK_CMD_LEADER ]) then
    
    # For example copy css, images and other static resources to S3 bucket serving static files
    if ([ -f $ELASTICBEANSTALK_APP_SCRIPT_DIR/$appName-setup/$appName-upload-static-resources.sh ]) then
        $ELASTICBEANSTALK_APP_SCRIPT_DIR/$appName-setup/$appName-upload-static-resources.sh
    fi
        
fi


# Do tasks to be performed by each instance on every deployment
if ([ -f $ELASTICBEANSTALK_APP_SCRIPT_DIR/$appName-setup/$appName-setup.sh ]) then
    $ELASTICBEANSTALK_APP_SCRIPT_DIR/$appName-setup/$appName-setup.sh
fi
