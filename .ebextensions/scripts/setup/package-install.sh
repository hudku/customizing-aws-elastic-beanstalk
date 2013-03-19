#!/bin/bash


# Execute "export DEBUG=1" to debug this script.
# Set value to 2 to debug this script and the scripts called within this script.
# Set value to 3,4,5 and so on to increase the nesting level of the scripts to be debugged.
[[ $DEBUG -gt 0 ]] && set -x; export DEBUG=$(($DEBUG - 1))


#
# Install all the required packages and utilities
#

yum -y install dos2unix java-1.6.0-openjdk-devel gcc mysql git rubygem-json perl-XML-XPath perl-File-Slurp

# Just an illustration
# yum -y install php-devel php php-mysql php-mbstring php-gd php-xml


# install elastic beanstalk command line utilities
if ([ ! -e /opt/aws/AWS-ElasticBeanstalk-CLI-2.2 ]) then
    pushd $ELASTICBEANSTALK_APP_DIR/tmp
    fileDownload=AWS-ElasticBeanstalk-CLI-2.2.zip
    urlDownload=https://s3.amazonaws.com/elasticbeanstalk/cli
    wget -q $urlDownload/$fileDownload
    unzip -q $fileDownload -d /opt/aws
    popd
fi

# install cloud formation command line utilities
if ([ ! -e /opt/aws/AWSCloudFormation-1.0.12 ]) then
    pushd $ELASTICBEANSTALK_APP_DIR/tmp
    fileDownload=AWSCloudFormation-cli.zip
    urlDownload=https://s3.amazonaws.com/cloudformation-cli
    wget -q $urlDownload/$fileDownload
    unzip -q $fileDownload -d /opt/aws
    popd
fi


# install dnscurl script to manage Route53
if ([ ! -e /opt/aws/bin/dnscurl.pl ]) then
    pushd /opt/aws/bin
    fileDownload=dnscurl.pl
    urlDownload=http://awsmedia.s3.amazonaws.com/catalog/attachments
    wget -q $urlDownload/$fileDownload
    chmod 700 dnscurl.pl
    popd
fi


# install s3cmd
if ([ ! -e /etc/yum.repos.d/s3tools.repo ]) then
    pushd /etc/yum.repos.d
    wget -q http://s3tools.org/repo/RHEL_6/s3tools.repo
    yum -y install s3cmd
    popd
fi
