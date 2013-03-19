#!/bin/bash

# Execute "export DEBUG=1" to debug this script.
# Set value to 2 to debug this script and the scripts called within this script.
# Set value to 3,4,5 and so on to increase the nesting level of the scripts to be debugged.
[[ $DEBUG -gt 0 ]] && set -x; export DEBUG=$(($DEBUG - 1))


#
# Copies application files from primary instance to secondary instance directory 
#



tomcatPrimaryInstanceName="$TOMCAT_PRIMARY_INSTANCE_NAME"
tomcatSecondaryInstanceName="$TOMCAT_SECONDARY_INSTANCE_NAME"

tomcatPrimaryInstanceDir="/usr/share/$tomcatPrimaryInstanceName"
tomcatSecondaryInstanceDir="/usr/share/$tomcatSecondaryInstanceName"


http8080Comment="HTTP 8080 Comment"


if ([ -z "$tomcatPrimaryInstanceName" ]) then
    echo "Error: Tomcat primary instance name is empty."
    exit 1
fi

if ([ -z "$tomcatSecondaryInstanceName" ]) then
    echo "Error: Tomcat secondary instance name is empty."
    exit 1
fi

if ([ ! -e "$tomcatPrimaryInstanceDir" ]) then
    echo "Error: Tomcat primary instance directory does not exist."
    exit 1
fi


rm -rf $tomcatSecondaryInstanceDir/bin
rm -rf $tomcatSecondaryInstanceDir/conf
rm -rf $tomcatSecondaryInstanceDir/webapps


cp -pLR $tomcatPrimaryInstanceDir/bin $tomcatSecondaryInstanceDir/
cp -pLR $tomcatPrimaryInstanceDir/conf $tomcatSecondaryInstanceDir/
cp -pLR $tomcatPrimaryInstanceDir/webapps $tomcatSecondaryInstanceDir/

# Set the directory and file permissions
chmod -R 777 $tomcatSecondaryInstanceDir/*
chown -R tomcat:tomcat $tomcatSecondaryInstanceDir/*


# For secondary instance remove the comments around HTTP 8080 connector
sed -i -e "/.*$http8080Comment.*/d" /$tomcatSecondaryInstanceDir/conf/server.xml

# Substitute the port numbers in server.xml
sed -i -e "s/8005/8105/g" -e "s/8080/8180/g" -e "s/8009/8109/g" -e "s/8443/8543/g" /$tomcatSecondaryInstanceDir/conf/server.xml


echo "Successfully copied the files to secondary tomcat instance $tomcatSecondaryInstanceName"
