#!/bin/bash

# Execute "export DEBUG=1" to debug this script.
# Set value to 2 to debug this script and the scripts called within this script.
# Set value to 3,4,5 and so on to increase the nesting level of the scripts to be debugged.
[[ $DEBUG -gt 0 ]] && set -x; export DEBUG=$(($DEBUG - 1))


#
# Stop the secondary instance
#


tomcatSecondaryInstanceName="$TOMCAT_SECONDARY_INSTANCE_NAME"



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


if ( ! $(isPortOpen 8009) ) then
    echo -e "Error: Tomcat primary instance port 8009 is not open. Please check.\n"
    exit 1
fi


if ( ! $(isProcessRunning "$tomcatSecondaryInstanceName") ) then
    echo "Error: Tomcat secondary instance $tomcatSecondaryInstanceName is not running. Please check."
    exit 1
fi

if ( ! $(isPortOpen 8109) ) then
    echo "Error: Port 8109 required by $tomcatSecondaryInstanceName is not open. Please check."
    exit 1
fi


# Remove the internal port redirections
iptables -D OUTPUT -t nat -p tcp -d 127.0.0.1 --dport 8080 -j REDIRECT --to-port 8180
iptables -D OUTPUT -t nat -p tcp -d 127.0.0.1 --dport 8009 -j REDIRECT --to-port 8109
iptables -D OUTPUT -t nat -p tcp -d 127.0.0.1 --dport 8443 -j REDIRECT --to-port 8543


# Stop the secondary instance
service $tomcatSecondaryInstanceName stop
if ([ $? -ne 0 ]) then
    echo "Error: Failed to stop the tomcat secondary instance $tomcatSecondaryInstanceName"
    exit 1 
fi

echo "Secondary tomcat instance $tomcatSecondaryInstanceName stopped successfully"
