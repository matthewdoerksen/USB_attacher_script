#!/bin/bash

# Usage:
# import this file from your other script:
# import=". $1/common_functions.sh $1"
# echo "Importing common functions from: $import"
# $import

# VM_NAME should be set in the calling script


MAX_RETRIES=3

# Will only attempt to attach/detach if all of the USB devices are present
# on the host machine. Does not revert any partial operations (i.e. 2 devices attach then 1 fails, 2 attached arenot detached)
# 1 yes
# 0 no
ALL_OR_NOTHING=1

SCRIPT_DIR="$1"

ATTACH_SCRIPT="$SCRIPT_DIR/attach_device.sh"
DETACH_SCRIPT="$SCRIPT_DIR/detach_device.sh"

HEX_PREPEND="0x"
SEPARATOR=":"
ATTACHER_STR="usb_auto_attacher_script_"





# Prints the specified message and exits with the provided exit code
# Arguments:
# 1: message to print
# 2: exit code
# 3: clean up XML files (1: yes, 0/no arg: no)
function printAndExit() {
    echo "$1"
    if [ $# -eq 3 ]; then
        if [ $3 -eq 1 ]; then
            cleanUpFiles
        fi
    fi
    exit $2
}



# Arguments:
# 1: number of retries attempted
# Function:
# Exits the script with a non-0 exit code if we've exceeded the retry limit
function exceededRetryLimitCheck() {
    if [ $1 -gt $MAX_RETRIES ]; then
        printAndExit "Command did not succeed for $MAX_RETRIES, exiting script unsuccessfully." 1
    fi
}


# Arguments:
# 1: cmd
# 2: expected output value (as an int)
function runCmdWithRetries() {
    retry=1
    cmd=$1
    expected=$2
    echo "Command: $cmd"
    echo "Expected exit code/value: $expected"
    code=$(eval "$cmd")

    while [[ $code -ne $expected && $retry -le $MAX_RETRIES ]]
    do
        echo "Exit code for sub-command was not $expected, retrying."
        let retry=$retry+1
        code=$(eval "$cmd")
    done

    exceededRetryLimitCheck $retry

    # safe to print out since we'll have failed earlier on retries if the exit code
    # didn't match what we wanted it to be
    return $expected
}




function isVmRunning() {
    echo "Checking to see if $VM_NAME is running"

    cmd="virsh list | grep \"$VM_NAME\" | grep -c -i \"running\""
    expectedVmCount=$(eval "$cmd")

    if [ "$expectedVmCount" -eq 0 ]; then
        printAndExit "$VM_NAME was not running, exiting script with nothing to do" 0 1
    elif [ $expectedVmCount -gt 1 ]; then
        echo "WARNING: XML files will not be cleaned up since they may still be in use."
        printAndExit "More than one VM with '$VM_NAME' was found, cannot successfully run script." 1
    else
        echo "$VM_NAME is running, continuing script execution."
    fi
}







# Returns 1 if a file matching the pattern exists (device *should be* attached already)
# Arguments:
# 1: device
# 2: xml file name
function checkDeviceXmlExists() {
    #echo "Checking to see if device $1 is already attached."
    cmd="ls | grep -c --include=\*.xml '$2'"
    echo "Command to check if XML file exists: $cmd"
    count=$(eval "$cmd")
    if [ ${count} -eq 0 ]; then
#        echo "No device XML file matching pattern found"
        return 0
    else
#        echo "XML files found matching pattern: ${xml_files[@]}" 
        return 1
    fi
}






# Generate the filename for a given USB device
# Arguments:
# 1: VENDOR_ID<SEPARATOR>PRODUCT_ID UNIQUE
function generateXmlFilename() {
    args=${1// /$SEPARATOR}
    # now VENDOR_ID<SEPARATOR>PRODUCT_ID<SEPARATOR>UNIQUE

    file="$ATTACHER_STR$VM_NAME-$args"
    file=${file//[^[:alnum:]]/_}
    # now USB_AUTO_ATTACHER_VM_VENDOR_PRODUCT_UNIQUE (anything like this as an XML should be safe to delete)
    echo "$file"
}





# Attaches the specified device
# Arguments:
# 1: VENDOR_ID:PRODUCT_ID UNIQUE
# 2: XML filename
function attach() {
    # split the vendor/product/unique to pass through to the attacher script
    args=${1// /$SEPARATOR}
    IFS="$SEPARATOR"
    read -ra tokens <<< "$args"

    # if tokens size is 2, then we have no unique string, pass in VENDOR:PRODUCT
    if [ ${#tokens[@]} -eq 2 ]; then
        tokens+=("${tokens[0]}$SEPARATOR${tokens[1]}")
    fi

    cmd="$ATTACH_SCRIPT $HEX_PREPEND${tokens[0]} $HEX_PREPEND${tokens[1]} $2 ${tokens[2]} \"$VM_NAME\""
    echo "Attach command: $cmd"
    stdout=$(eval "$cmd")
    exitCode=$?

    # 0 - success
    # 1 - already attached
    # 2 - other error
    #echo "Exit code from attempting to attach device: $exitCode"

    if [ $exitCode -eq 0 ]; then
        echo "Succesfully attached device"
    elif [ $exitCode -eq 1 ]; then
        # might be attached to a different VM
        cmd="echo $stdout | grep -c -i 'is in use by driver QEMU, domain $VM_NAME'"
        runCmdWithRetries "$cmd" 1
        exitCode=$?
        if [ $exitCode -eq 1 ]; then
            echo "USB device is already attached to this VM."
        elif [ $ALL_OR_NOTHING -eq 1 ]; then
            echo "All or nothing was specified, a non-0/1 exit code occurred."
            exit 1
        fi
    else
        echo "Another error occurred trying to attach the device."
    fi
}





# Arguments:
# 1: VENDOR_ID<SEPARATOR>PRODUCT_ID UNIQUE
# 4: XML FILE
function detach() {
    # split the vendor/product/unique to pass through to the detacher script
    args=${1// /$SEPARATOR}
    IFS="$SEPARATOR"
    read -ra tokens <<< "$args"

    # if tokens size is 2, then we have no unique string, pass in VENDOR:PRODUCT
    if [ ${#tokens[@]} -eq 2 ]; then
        tokens+=("${tokens[0]}$SEPARATOR${tokens[1]}")
    fi

    cmd="$DETACH_SCRIPT $HEX_PREPEND${tokens[0]} $HEX_PREPEND${tokens[1]} $2 ${tokens[2]} \"$VM_NAME\""
    echo "Detach command: $cmd"
    #stdout=$(eval "$cmd")
    #exitCode=$?
}




# Adds a device into the array of devices
# Also adds the generated XML filename for the device to device_xml_files
# Arguments:
# 1: vendor id
# 2: product id
# 3: unique
function addDevicesToGlobalMap() {
    devices+=("$1$SEPARATOR$2 $3")
    echo "Generating filename for device"
    fileName=$(generateXmlFilename "$1$SEPARATOR$2 $3")
    echo "Auto-generated filename: $fileName"
    device_xml_files+=("$fileName")
}



function areUsbDevicesAttachedToHost() {
    # cycle through list of devices, see how many are found
    # if all or nothing is specified, quit if it doesn't match

    found_devices=()

    # skip over odd values since that's the file tag
    for ((i = 0; i < ${#devices[@]}; i++))
    do
        device=${devices[$i]}
        echo "Checking if device: $device is attached to physical machine."
        cmd="lsusb | grep -c '$device'"
        grepCount=$(eval $cmd)
        if [[ $grepCount -eq 0 && $ALL_OR_NOTHING -eq 1 ]]; then
            printAndExit "All or nothing was specified and we couldn't find one or more devices, attached device will be removed from the VM and exiting script normally." 0 1
        else
            found_devices+=("$device")
            echo "Added $device to list of devices found (may or not be attached to VM already)"
        fi
    done
}




function cleanUpFiles() {
    echo "Cleaning up temporary files"
    for f in "${device_xml_files[@]}"
    do
        cmd="find . -name $f*"
        matchingFiles=$(eval "$cmd")

        # if noFile = __ then there weren't any files
        # can't just check array size since it comes back as 1 after eval
        noFile="_${matchingFiles[@]}_"
        echo "Command to find XML files detailing device to detach: $cmd"

        # if no device found, skip
        if [ "${noFile}" == "__" ]; then
            echo "No XML file found, device cannot be attached so it will be skipped"
        else
            echo "Matching XML files for devices to detach: ${matchingFiles[@]}"    
            for xml in "${matchingFiles[@]}"
            do
                virsh detach-device "$VM_NAME" "$xml"
                rm "$xml"
                echo "Detached and deleted '$f'"
            done
        fi
    done
}





function attachDevices() {
    # check if files exist, if so, exit (nothing to attach, unless force option is specified)
    # if vm is running but no files exist, detach then attach
    # attach devices to VM
    for ((i = 0; i < ${#found_devices[@]}; i++))
    do
        device=${found_devices[$i]}
        xml=${device_xml_files[$i]}
        checkDeviceXmlExists "$device" $xml
        attached=$?
        #echo "Exit code from checkDeviceXmlExists: $attached"
        if [ $attached -eq 0 ]; then
            attach "$device" "$xml"
        else
            echo "Device $device already attached"
        fi
        echo ""
        echo ""
    done
}
