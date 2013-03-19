#!/bin/bash

# Execute "export DEBUG=1" to debug this script.
# Set value to 2 to debug this script and the scripts called within this script.
# Set value to 3,4,5 and so on to increase the nesting level of the scripts to be debugged.
[[ $DEBUG -gt 0 ]] && set -x; export DEBUG=$(($DEBUG - 1))


#
# Does one time setting necessary to setup a secondary tomcat instance.
#


tomcatPrimaryInstanceName="$TOMCAT_PRIMARY_INSTANCE_NAME"
tomcatSecondaryInstanceName="$TOMCAT_SECONDARY_INSTANCE_NAME"

tomcatPrimaryInstanceDir="/usr/share/$tomcatPrimaryInstanceName"
tomcatSecondaryInstanceDir="/usr/share/$tomcatSecondaryInstanceName"



# include all the utility scripts
source $ELASTICBEANSTALK_APP_SCRIPT_DIR/include/include.sh


if ([ -z "$tomcatPrimaryInstanceName" ]) then
    exit 1
fi

if ([ -z "$tomcatSecondaryInstanceName" ]) then
    exit 1
fi

if ([ ! -e "$tomcatPrimaryInstanceDir" ]) then
    echo "Error: Tomcat primary instance directory does not exist."
    exit 1
fi


# Create a link to the existing init script file. The name used for the link becomes the name of the tomcat instance
if ([ ! -e /etc/init.d/$tomcatSecondaryInstanceName ]) then
    ln -s /etc/init.d/$tomcatPrimaryInstanceName /etc/init.d/$tomcatSecondaryInstanceName
    chmod 755 /etc/init.d/$tomcatSecondaryInstanceName
fi

# Copy the contents of the main configuration and the configuration file in /etc/sysconfig and substitute the instance name 
/bin/cp -f /etc/$tomcatPrimaryInstanceName/$tomcatPrimaryInstanceName.conf /etc/sysconfig/$tomcatSecondaryInstanceName
cat /etc/sysconfig/$tomcatPrimaryInstanceName >> /etc/sysconfig/$tomcatSecondaryInstanceName
sed -i "s/$tomcatPrimaryInstanceName/$tomcatSecondaryInstanceName/g" /etc/sysconfig/$tomcatSecondaryInstanceName

if [ -e $tomcatSecondaryInstanceDir ]; then
    echo "$tomcatSecondaryInstanceDir folder already exists. Nothing more to do."
    exit 0 
fi

# Create the tomcat instance directory
rm -rf $tomcatSecondaryInstanceDir
mkdir -p $tomcatSecondaryInstanceDir
chmod 775 $tomcatSecondaryInstanceDir

# Create the logs directory
mkdir -p $tomcatSecondaryInstanceDir/logs

# Create temp and work directories
mkdir -p /var/cache/$tomcatSecondaryInstanceName/temp
mkdir -p /var/cache/$tomcatSecondaryInstanceName/work
chmod -R 770 /var/cache/$tomcatSecondaryInstanceName
chown -R tomcat:tomcat /var/cache/$tomcatSecondaryInstanceName

# Create the links for temp and work directories
ln -s /var/cache/$tomcatSecondaryInstanceName/temp $tomcatSecondaryInstanceDir/temp
ln -s /var/cache/$tomcatSecondaryInstanceName/work $tomcatSecondaryInstanceDir/work

# Copy the "lib" link from the primary instance
cp -d $tomcatPrimaryInstanceDir/lib $tomcatSecondaryInstanceDir/


# Set the directory and file permissions
chmod -R 777 $tomcatSecondaryInstanceDir/*
chown -R tomcat:tomcat $tomcatSecondaryInstanceDir/*

echo "Success. Secondary tomcat instance $tomcatSecondaryInstanceName has been setup successfully."

