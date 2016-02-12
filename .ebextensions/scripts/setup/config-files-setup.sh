#!/bin/bash


# Execute "export DEBUG=1" to debug this script.
# Set value to 2 to debug this script and the scripts called within this script.
# Set value to 3,4,5 and so on to increase the nesting level of the scripts to be debugged.
[[ $DEBUG -gt 0 ]] && set -x; export DEBUG=$(($DEBUG - 1))


#
# Setup all the configuration files
#


# Substitute the AWS credential values into the beanstalk configuration file which is used to create new beanstalk environments
if ([ -f $ELASTICBEANSTALK_APP_DATA_DIR/beanstalk-configuration.txt ]) then
	sed -i -e "s/\"Value\": \"AWS_ACCESS_KEY_ID\"/\"Value\": \"$AWS_ACCESS_KEY\"/" $ELASTICBEANSTALK_APP_DATA_DIR/beanstalk-configuration.txt
	sed -i -e "s/\"Value\": \"AWS_SECRET_KEY\"/\"Value\": \"$AWS_SECRET_KEY\"/" $ELASTICBEANSTALK_APP_DATA_DIR/beanstalk-configuration.txt
fi


# Alter tomcat properties file
if ([ -f /etc/tomcat7/catalina.properties ]) then
    # Add the line if not already present
	term="org.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH"
    grep -q $term /etc/tomcat7/catalina.properties || echo -e "\n\n$term=true\n" >> /etc/tomcat7/catalina.properties
fi


# Alter apache and tomcat configuration files for the current EC2 instance type
if ([ "$EC2_INSTANCE_TYPE" == "t1.micro" ]) then
    
    if ([ -f /etc/tomcat7/server.xml ]) then
        sed -i 's|\(AJP/1\.3.*\)minSpareThreads=.*maxThreads="[^"]*"|\1|' /etc/tomcat7/server.xml
    fi
    
    fileToModify=/etc/httpd/conf/httpd.conf 
    if ([ -f $fileToModify ]) then
        sed -i 's|StartServers\s\+[0-9]\+\s*|StartServers 4|' $fileToModify
        sed -i 's|MinSpareServers\s\+[0-9]\+\s*|MinSpareServers 20|' $fileToModify
        sed -i 's|MaxSpareServers\s\+[0-9]\+\s*|MaxSpareServers 30|' $fileToModify
    fi
    
else

    # On production machine, modify java options to increase the minimum memory and do not specify any maximum memory.
    if ([ -f /tmp/deployment/config/tomcat7 ]) then
        sed -i 's|-Xms256m|-Xms2048m|g' /tmp/deployment/config/tomcat7
        sed -i 's| -Xmx256m||g' /tmp/deployment/config/tomcat7
    fi
        
fi
