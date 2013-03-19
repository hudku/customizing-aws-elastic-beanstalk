#!/bin/bash

# Set DEBUG to 1 to debug this script. 2 for debugging scripts called by this script and so on.
# Execute "export DEBUG=1" to debug this script.
# Set value to 2 to debug this script and the scripts called within this script.
# Set value to 3,4,5 and so on to increase the nesting level of the scripts to be debugged.
[[ $DEBUG -gt 0 ]] && set -x; export DEBUG=$(($DEBUG - 1))



# Check if this is the very first time that this script is running
if ([ ! -f /root/.not-a-new-instance.txt ]) then
    newEC2Instance=true
fi



# Get the directory of 'this' script
dirCurScript=$(dirname "${BASH_SOURCE[0]}")

# Fix the line endings of all files
find $dirCurScript/../../ -type f | xargs dos2unix -q -k

# Get the app configuration environment variables
source $dirCurScript/../../copy-to-slash/root/.elastic-beanstalk-app
export ELASTICBEANSTALK_APP_DIR="/$ELASTICBEANSTALK_APP_NAME"

appName="$ELASTICBEANSTALK_APP_NAME"
dirApp="$ELASTICBEANSTALK_APP_DIR"

dirAppExt="$ELASTICBEANSTALK_APP_DIR/.ebextensions"
dirAppTmp="$ELASTICBEANSTALK_APP_DIR/tmp"

dirAppData="$dirAppExt/data"
dirAppScript="$dirAppExt/scripts"


# Create tmp directory
mkdir -p $dirApp/tmp

# Set permissions
chmod 777 $dirApp
chmod 777 $dirApp/tmp
chmod -R 700 $dirAppScript

# Set permissions to run package installation script which needs some files in this folder
chmod -R 644 $ELASTICBEANSTALK_APP_DIR/.ebextensions/copy-to-slash/etc



# Redirect stdout and stderr and append it to our file
curDateTime=$(date "+%Y%m%d%H%M%S")
mkdir -p $dirAppTmp/app-setup-log
exec &>> $dirAppTmp/app-setup-log/app-setup-log-$curDateTime.txt
echo $(date)



if ([ $newEC2Instance ]) then
    # Allow sudo command to be used as part of beanstalk ebextensions scripts without a terminal
    grep -q 'Defaults:root !requiretty' /etc/sudoers.d/$appName || echo -e 'Defaults:root !requiretty\n' > /etc/sudoers.d/$appName
    chmod 440 /etc/sudoers.d/$appName
    
    # Add sudo command if not already present to .bashrc of ec2-user so that we are logged on as root when we use ssh
    grep -q "sudo -s" /home/ec2-user/.bashrc || echo -e "\nsudo -s\n" >> /home/ec2-user/.bashrc
fi



# Install all required packages and command line utilities
if ([ $newEC2Instance ]) then
    $dirAppScript/setup/package-install.sh
fi



# Backup original files which we are going to overwrite
$dirAppScript/setup/config-files-backup.sh

# Copy the directory structure which could overwrite some existing files with our version 
$dirAppScript/setup/copy-to-slash.sh



# Setup AWS credentials so that all AWS command line utilties can work
$dirAppScript/setup/aws-credentials-setup.sh



# Remove env-result.sh so that it gets created newly
if ([ -f ~/env-result.sh ]) then
    rm -rf ~/env-result.sh
fi

# Ensuring all the required environment settings after all the above setup
if ([ -f ~/.bash_profile ]) then
    source ~/.bash_profile
fi

# include all the utility scripts
source $dirAppScript/include/include.sh



# Mount all local hard disks present, create swap file if not already present and reboot if swap file is newly created. 
if ([ $newEC2Instance ]) then
    $dirAppScript/util/mount-all-instance-storage.sh
fi



# Setup config files
$dirAppScript/setup/config-files-setup.sh

# Setup logging facility
$dirAppScript/setup/logs-setup.sh

# Setup crontab to run the routine tasks
$dirAppScript/setup/crontab-setup.sh

        
# Setup tomcat secondary instance configuration
$dirAppScript/setup/tomcat-setup-secondary.sh


# Setup apache web directories
if ([ $newEC2Instance ]) then
    
    # Create apache web directory and set permissions
    if ([ ! -z "$APACHE_DIR" ]) then
        mkdir -p $APACHE_DIR
        chmod -R 755 $APACHE_DIR
    fi
        
fi



# Do application specific custom setup
$dirAppScript/setup/app-custom-setup.sh



# Commands to be executed only by the leader of AutoScaling group
if ([ $ELASTICBEANSTALK_CMD_LEADER ]) then
    
    # Update DNS records of current instance
    $dirAppScript/setup/route53-update-dns.sh

fi



# If apache is running then reload it.
$(isProcessRunning "httpd") && sudo service httpd reload



# If new instance, now it is not new anymore
if ([ $newEC2Instance ]) then
    echo -n "" > /root/.not-a-new-instance.txt
fi


# Print the finish time of this script
echo $(date)


# Always successful exit so that beanstalk does not stop creating the environment
exit 0
