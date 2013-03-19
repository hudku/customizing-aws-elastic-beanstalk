#!/bin/bash


#set -x

#
# Includes all the utility functions.
# Usage: source include.sh
# Tip: You could also execute "source include.sh" from the bash prompt to make all these utility functions available in your shell.

function getCurScriptPath()
{
    local scriptPath
    
	pushd . > /dev/null
	
	scriptPath="${BASH_SOURCE[0]}";
	
	# Handle if symbolic link is used
    if ([ -h "${scriptPath}" ]) then
	   while ([ -h "${scriptPath}" ])
	   do
	       cd $(dirname "$scriptPath") > /dev/null
	       scriptPath=$(readlink "${scriptPath}")
       done
	fi
	
	cd $(dirname ${scriptPath}) > /dev/null
	scriptPath=$(pwd);
	
	popd  > /dev/null
	
	echo $scriptPath
}


# Obtain the path of 'this' script file
curScriptPath=$(getCurScriptPath)


# Now include all the utility scripts
source $curScriptPath/bash-util.sh
source $curScriptPath/string-util.sh
