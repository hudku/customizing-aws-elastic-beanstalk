#!/bin/bash

# Execute "export DEBUG=1" to debug this script.
# Set value to 2 to debug this script and the scripts called within this script.
# Set value to 3,4,5 and so on to increase the nesting level of the scripts to be debugged.
[[ $DEBUG -gt 0 ]] && set -x; export DEBUG=$(($DEBUG - 1))


#
# Mount all the available instance storages, resize the root volume to its maximum available size and
#   create a swap file if not present. If the swap file is created newly, then reboot.
#


memorySizeInMB=$(free -m | grep "Mem:" | awk '{print $2}')

swapFileSizeInGB=1
if ([ $memorySizeInMB -lt 2048 ]) then
    swapFileSizeInGB=2
fi

# By specifying mnt2 we are trying to use instance storage if available
swapFileDir="/mnt2"
swapFileName="swap_file"

swapFileLinkDir=/var/cache/swap



# Array to hold all the devices found
aDevices=()



function addDeviceToArray()
{
    local newDevice=$1
    
    aDevices=( "${aDevices[ @ ]}" $newDevice )
}

function addDeviceIfPresent()
{
    local device=$1
    
    if ([ -e $device ]) then
        addDeviceToArray $device
    fi
}

function checkAllDevices()
{
    addDeviceIfPresent /dev/sda2
    addDeviceIfPresent /dev/sda3
    addDeviceIfPresent /dev/sdb
    addDeviceIfPresent /dev/sdc
    addDeviceIfPresent /dev/sdd
    addDeviceIfPresent /dev/sde
}

function makeDeviceEntry()
{
    local device=$1
    local mountLocation=$2
    local entry
    
    entry="$device       $mountLocation    ext4   defaults        0   0"
    echo -e "Formatting... before making the entry - \"$entry\""

    sudo mkfs -t ext4 $device > /dev/null

    mkdir -p $mountLocation
    if ([ $? -eq 0 ]) then
        echo "$entry" >> /etc/fstab
    fi
}

function makeAllDeviceEntries()
{
    for (( deviceIndex = 0; deviceIndex < ${#aDevices[@]}; deviceIndex++ ))
    do
        deviceMountLocation=/mnt
        if ([ $deviceIndex -gt 0 ]) then
            deviceMountLocation=$deviceMountLocation$(( $deviceIndex+1 ))
        fi
        
        makeDeviceEntry ${aDevices[ $deviceIndex ]} $deviceMountLocation
    done
}


function createSwapFile()
{
    local swapFileDir=$1
    local swapFileName=$2
    local swapFileSizeInGB=$3
    local swapFileLinkDir=$4
    
    mkdir -p $swapFileLinkDir
    mkdir -p $swapFileDir$swapFileLinkDir
	
    # Create the swap file of size specified in GB
    dd if=/dev/zero of=$swapFileDir$swapFileLinkDir/$swapFileName bs=1M count=$((swapFileSizeInGB * 1024))
	
    # Set the directory and file permissions
    chmod -R 600 $swapFileDir
    chown -R root:root $swapFileDir
	
    # Create a link to the swap file and set the permissions
    ln -s $swapFileDir$swapFileLinkDir/$swapFileName $swapFileLinkDir/$swapFileName
    chmod -R 600 $swapFileLinkDir
    chown -R root:root $swapFileLinkDir
	
    # Make the swap file (use force option to suppress warning and to not waste the first page)
    sudo mkswap -f $swapFileDir$swapFileLinkDir/$swapFileName
	
    # Setup fstab to make the changes permanent
    echo "$swapFileLinkDir/$swapFileName   swap      swap     defaults          0 0" >> /etc/fstab
	
    # Turn the swap ON (Still reboot may be required)
    sudo swapoff -a
    sudo swapon -a  # Turns on the swap specified in fstab

    # If everything succeeded then forcibly reboot for the swap file to come into effect 
    if ([ $? -eq 0 ]) then
        echo "Rebooting the machine for the swap file to take effect - $(date)"
        sudo reboot -f
    fi
}



# Check if our swap file exists.
if ([ -e $swapFileDir$swapFileLinkDir/$swapFileName ]) then
    echo "Our swap file exists. That means this script has been already run. Nothing to do."
    exit 0
fi

# Try resizing root volume in case if it is not already done
if ([ -e /dev/sda1 ]) then
    sudo resize2fs /dev/sda1
fi

# umount ephemeral0 so that we can format it    
if ([ -e /media/ephemeral0 ]) then
    sudo umount /media/ephemeral0
fi
    
checkAllDevices
makeAllDeviceEntries

# mount all the entries found in /etc/fstab
sudo mount -a

# Create the swap file after mounting all the devices
createSwapFile $swapFileDir $swapFileName $swapFileSizeInGB $swapFileLinkDir
