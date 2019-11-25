#!/bin/bash

# This script does not handle devices that are already attached to other VMs
# What should be done is to ensure physical devices attached are unique/not shared


# USE CASES/TESTS
# 1 - VM running
#     - attempt to attach with no devices attached (do nothing): PASS
#     - attempt to attach with devices attached (attach): PASS
#     - attempt to attach with device already attached (do nothing): PASS
#
# 2 - VM not running
#     - attempt to attach with no devices attached (detach/delete): PASS
#     - attempt to attach with devices attached (XML exists) (detach/delete): PASS
#     - attempt to attach with devices attached (no XML exists) (do nothing): PASS


# Arguments:
# 1: Path to the script directory
# 2: (optional) detach (string, keyword)

# Source common functions
import=". $1/common_functions.sh $1"
echo "Importing common functions from: $import"
$import

detach=0
if [[ "$#" -eq 2 && "$2" -eq "detach" ]]; then
    detach=1
    echo "Detach flag was specified, all devices will be removed"
fi


# works with spaces too (but in the name of the xml file they'll be replaced with underscores)
# VM_NAME="Windows 8.1 NHL + Emulator"
VM_NAME="Windows_10"

KBD_VENDOR_ID="1b1c"
KBD_PRODUCT_ID="1b15"
KBD_UNIQUE="Corsair"

MOUSE_VENDOR_ID="258a"
MOUSE_PRODUCT_ID="1007"
# if the unique identifier string is blank, we will use the VENDOR<SEPARATOR>PRODUCT instead
MOUSE_UNIQUE=""

BT_VENDOR_ID="0a12"
BT_PRODUCT_ID="0001"
BT_UNIQUE="Cambridge Silicon Radio"

MIC_VENDOR_ID="0c76"
MIC_PRODUCT_ID="161f"
MIC_UNIQUE="JMTek"

devices=()
declare -a device_xml_files
declare -a found_devices



####################
#
# Entry Point
#
####################

# add all devices
addDevicesToGlobalMap "$KBD_VENDOR_ID" "$KBD_PRODUCT_ID" "$KBD_UNIQUE"
addDevicesToGlobalMap "$MOUSE_VENDOR_ID" "$MOUSE_PRODUCT_ID" "$MOUSE_UNIQUE"
addDevicesToGlobalMap "$BT_VENDOR_ID" "$BT_PRODUCT_ID" "$BT_UNIQUE"
addDevicesToGlobalMap "$MIC_VENDOR_ID" "$MIC_PRODUCT_ID" "$MIC_UNIQUE"

echo ""
echo ""

# if the detach flag was specified, remove everything
if [ "$detach" -eq 1 ]; then
    printAndExit "Detach flag specified, removing devices and clean up XML files" 0 1
fi



# quits if the VM isn't running
# if applicable, cleans up temp files
isVmRunning

echo ""
echo ""

# check if USB devices are attached, if not, delete XML files and quit
# sets found_devices (global)
# exits and cleans up XML files if devices are not attached
areUsbDevicesAttachedToHost

echo ""
echo ""

# attach devices if not already attached
attachDevices


exit 0
