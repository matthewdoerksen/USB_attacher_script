#!/bin/bash

# EXIT CODES
# 0 - attached device successfully
# 1 - already attached (no-op)
# 2 - not attached successfully

# 0x0079:0x0011 SNES USB controller
#VENDOR_ID="0x0079"
#PRODUCT_ID="0x0011"
#BASE_FILE="snes_controller"
#UNIQUE_SEARCH="Dragon"
#VM="Lakka"

VENDOR_ID="$1"
PRODUCT_ID="$2"
BASE_FILE="$3"
UNIQUE_SEARCH="$4"
VM="$5"

# pull the bus for the device
BUS=$(lsusb | grep ${UNIQUE_SEARCH} | cut -d' ' -f2 | cut -d':' -f1 | cut -d' ' -f1 | cut -d'0' -f3 | cut -d$'\n' -f1)
BUS=($(echo ${BUS} | sed 's/^0*//'))

# pull the device ID(s) (handles duplicate devices like game controllers)
DEVICES=($(lsusb | grep ${UNIQUE_SEARCH} | cut -d' ' -f2,4 | cut -d':' -f1 | cut -d' ' -f2))

# go through the device IDs and strip leading 0s since they'll mess with the attach process
for ((i=0;i<${#DEVICES[@]};i++)); do
  DEVICES[i]=$(echo ${DEVICES[i]} | sed 's/^0*//')
done

# iterate over all devices and create the XML for each (and attach)
for ((i=0;i<${#DEVICES[@]};i++)); do
  XML="<hostdev mode='subsystem' type='usb' managed='no'><source><vendor id='${VENDOR_ID}'/><product id='${PRODUCT_ID}'/><ad$
  DEVICE_CONFIG="${BASE_FILE}_$i.xml"
  echo "$XML" > "$DEVICE_CONFIG"
  echo "Wrote XML file: $DEVICE_CONFIG"

  echo "Attempting to attach device (Vendor): ${VENDOR_ID}, (Product): ${PRODUCT_ID}, (Bus): ${BUS}, (ID): ${DEVICES[i]}"
  OUTPUT=$(virsh attach-device "$VM" "$DEVICE_CONFIG" 2>&1)
  EXIT_CODE=$(echo "$?")

  echo "Did the device attach successfully? Exit code: $EXIT_CODE"
  if [ $EXIT_CODE -gt 0 ]; then

    # turn our unsuccessful exit code + text into one of our exit codes
    # is it already attached?
    echo "$OUTPUT" | grep "is in use by driver QEMU"
    EXIT_CODE=$(echo "$?")

    if [ $EXIT_CODE -eq 0 ]; then
      echo "Device already attached, exiting with exit code 1"
      exit 1
    fi

    # exit with some other code
    exit 2
  fi
  # if we get here the device attached successfully, either exit or continue with the next device
done
