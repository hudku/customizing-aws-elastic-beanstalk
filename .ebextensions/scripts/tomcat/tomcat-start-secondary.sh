#!/bin/bash

# Execute "export DEBUG=1" to debug this script.
# Set value to 2 to debug this script and the scripts called within this script.
# Set value to 3,4,5 and so on to increase the nesting level of the scripts to be debugged.
[[ $DEBUG -gt 0 ]] && set -x; export DEBUG=$(($DEBUG - 1))


#
# Start the secondary instance
#


waitingTimeInSeconds=10

tomcatPrimaryInstanceName="$TOMCAT_PRIMARY_INSTANCE_NAME"
tomcatSecondaryInstanceName="$TOMCAT_SECONDARY_INSTANCE_NAME"

tomcatPrimaryInstanceDir="/usr/share/$tomcatPrimaryInstanceName"
tomcatSecondaryInstanceDir="/usr/share/$tomcatSecondaryInstanceName"

urlToTest="http://localhost:8180/search/business_listings/Resorts%20in%20Goa"


# include all the utility scripts
source $ELASTICBEANSTALK_APP_SCRIPT_DIR/include/include.sh


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


if ( ! $(exists $tomcatSecondaryInstanceDir/webapps/ROOT/*) ) then
    echo "Error: Did not find any valid file in the directory $tomcatSecondaryInstanceDir/webapps/ROOT/"
    echo "Run tomcat-copy-app-to-secondary.sh and try again."
    exit 1
fi

if ( $(isProcessRunning "$tomcatSecondaryInstanceName") ) then
    echo "Error: Tomcat secondary instance $tomcatSecondaryInstanceName seems to be already running. Please check."
    exit 1
fi

if ( $(isPortOpen 8109) ) then
    echo "Error: Port 8109 is open and is being used by some unknown process. Please check."
    exit 1
fi


# Start the secondary instance
service $tomcatSecondaryInstanceName start
if ([ $? -ne 0 ]) then
    echo "Error: Failed to start the instance $tomcatSecondaryInstanceName"
    exit 1 
fi


echo "Waiting for $waitingTimeInSeconds seconds to allow the tomcat instance $tomcatSecondaryInstanceName to start"
sleep $waitingTimeInSeconds 

echo "Trying to access the URL $urlToTest"
status=$(getHTTPResponseStatus "$urlToTest")
if ([ $status -ne 200 ]) then
    echo "Error: http://localhost:8180 failed with status $status"
    exit 1
fi


# Remove the redirection in case if they exist
iptables -D OUTPUT -t nat -p tcp -d 127.0.0.1 --dport 8080 -j REDIRECT --to-port 8180 2> /dev/null
iptables -D OUTPUT -t nat -p tcp -d 127.0.0.1 --dport 8009 -j REDIRECT --to-port 8109 2> /dev/null
iptables -D OUTPUT -t nat -p tcp -d 127.0.0.1 --dport 8443 -j REDIRECT --to-port 8543 2> /dev/null

# Set up the internal redirection of primary instance tomcat ports to secondary instance
iptables -A OUTPUT -t nat -p tcp -d 127.0.0.1 --dport 8080 -j REDIRECT --to-port 8180
iptables -A OUTPUT -t nat -p tcp -d 127.0.0.1 --dport 8009 -j REDIRECT --to-port 8109
iptables -A OUTPUT -t nat -p tcp -d 127.0.0.1 --dport 8443 -j REDIRECT --to-port 8543

echo "Secondary tomcat instance $tomcatSecondaryInstanceName started successfully"
