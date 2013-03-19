#!/bin/bash


#set -x


#
# Usage: source string-util.sh
#


# Usage: padLeft sInput padLength padChar
function padLeft
{
    local word="$1"

    while [ ${#word} -lt $2 ]; do
        word="$3$word";
    done;

    echo "$word";
}

# Usage: padRight sInput padLength padChar
function padRight
{
    local word="$1"

    while [ ${#word} -lt $2 ]; do
        word="$word$3";
    done;

    echo "$word";
}



# Usage: trimLeft sInput [charsToTrim]
function trimLeft()
{
    local sInput=$1
    local charsToTrim=$2
    local result
    
    if [ -z $charsToTrim ]; then
        charsToTrim=" \\t\\r\\n"
    fi
    
    result=$(echo -e $sInput | sed -e "s/^[$charsToTrim]*//")
    
    echo $result
}

# Usage: trimRight sInput [charsToTrim]
function trimRight()
{
    local sInput=$1
    local charsToTrim=$2
    local result
    
    if [ -z $charsToTrim ]; then
        charsToTrim=" \\t\\r\\n"
    fi
    
    result=$(echo -e $sInput | sed -e "s/[$charsToTrim]*$//")
    
    echo $result
}
