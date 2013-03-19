#!/bin/bash


#set -x

#
# Usage: source bash-util.sh
#


# Usage: die Message
function die()
{
    local message
    
    message=$1
    if ([ -z "$message" ]) then
        message="Error: Operation failed."
    fi
    
    echo -e "$message"
    
    exit 1
}



# Usage: getFileOrDirCount Path-or-FileName
# Description: bash -f or -e fail if wildcard is used in the name and it results in more than one entry
# See Also: exists
function getFileOrDirCount()
{
    local count
    
    count=$(ls -1 $1 2> /dev/null | wc -l)
    echo $count
}


# Usage: exists Path-or-FileName
# See Also: getFileOrDirCount
function exists()
{
    [ $(getFileOrDirCount "$1") -gt 0 ]
}



# Usage: getNonEmptyFileCount dirName fileNamePattern
# See Also: existsNonEmptyFile
function getNonEmptyFileCount()
{
    local count

    count=$(find $1 -size +0  -name "$2" 2> /dev/null | wc -l)
    echo $count
}


# Usage: existsNonEmptyFile  dirName fileNamePattern
# See Also: getNonEmptyFileCount
function existsNonEmptyFile()
{
    [ $(getNonEmptyFileCount "$1" "$2") -gt 0 ]
}



# Usage: getHTTPResponseStatus URL
function getHTTPResponseStatus()
{
    local result
    
    result=$(curl -s -o /dev/null -I -w "%{http_code}" "$1")
    
    echo $result
}


# Usage: getIPOfURL URL
function getIPOfURL()
{
    local ip
    
    if ([ ! -z "$1" ]) then
        # In case if dig lists CNAME then take the last line
        ip=$(dig $1 +short | tail -1)
    fi
    
    echo $ip
}


# Usage: getProcessPID processName
function getProcessPID()
{
    echo $(ps -ef | grep "$1" | head -1 | grep -v grep | awk '{print $2}')
}

# Usage: isProcessRunning processName
function isProcessRunning()
{
    [ ! -z $(getProcessPID "$1") ]
}

# Usage: isPortOpen portNumber
function isPortOpen()
{
    local result
    
    if ([ ! -z "$1" ]) then
        result=$(netstat -ln --tcp | grep "$1\s.*\sLISTEN")
    fi
    
    [ ! -z "$result" ]
}



# Usage: Prompt user making it easy to say no
function promptDefaultNo()
{
    local msgPrompt
    local answer
    
    msgPrompt=$1
    if ([ -z "$msgPrompt" ]) then
        msgPrompt="Continue (Yes/no)?"
    fi

    while true; do    
        read -p "$msgPrompt" answer
        case "$answer" in 
            Yes ) echo "y"; break;;
            n|N|no|No ) echo "n"; break;;
            * ) echo "Please answer Yes or no.";;
        esac
    done
}


# Usage: Prompt user making it easy to say yes
function promptDefaultYes()
{
    local msgPrompt
    local answer
    
    msgPrompt=$1
    if ([ -z "$msgPrompt" ]) then
        msgPrompt="Continue (yes/No)?"
    fi

    while true; do    
		read -p "$msgPrompt" answer
		case "$answer" in 
		    y|Y|yes|Yes ) echo "y"; break;;
		    No ) echo "n"; break;;
		    * ) echo "Please answer yes or No.";;
		esac
    done
}



# Usage: sendEmail emailList emailSubject emailMessage
function sendEmail()
{
    echo -e "\"$3\"" | mail -s "$2" "$1"
}
