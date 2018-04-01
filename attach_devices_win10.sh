#!/bin/bash
# grep exit code 0 - line found
#                1 - line NOT found
#                2 - error occurred during search

# attach Corsair kbd
/mnt/user/Common/Lakka_Emulation_Station/attach_device.sh 0x1b1c 0x1b15 kbd Corsair Windows_10
EXITCODE=$(echo "$?")
# if = 0, then successfully attached, 1 = already attached (no-op), 2 - other error, detach and attempt re-attach
while [ $EXITCODE -eq 2 ]
do
  /mnt/user/Common/Lakka_Emulation_Station/detach_device.sh 0x1b1c 0x1b15 kbd Corsair Windows_10
  /mnt/user/Common/Lakka_Emulation_Station/attach_device.sh 0x1b1c 0x1b15 kbd Corsair Windows_10
  EXITCODE=$(echo "$?")
  echo "Exit code attempting to detach and re-attach device: $EXITCODE"
done


# attach Primax mouse
/mnt/user/Common/Lakka_Emulation_Station/attach_device.sh 0x0461 0x4d99 mouse Primax Windows_10
EXITCODE=$(echo "$?")
# if = 0, then successfully attached, 1 = already attached (no-op), 2 - other error, detach and attempt re-attach
while [ $EXITCODE -eq 2 ]
do
  /mnt/user/Common/Lakka_Emulation_Station/detach_device.sh 0x0461 0x4d99 mouse Primax Windows_10
  /mnt/user/Common/Lakka_Emulation_Station/attach_device.sh 0x0461 0x4d99 mouse Primax Windows_10
  EXITCODE=$(echo "$?")
  echo "Exit code attempting to detach and re-attach device: $EXITCODE"
done


# attach JMTek microphone
/mnt/user/Common/Lakka_Emulation_Station/attach_device.sh 0x0c76 0x161f microphone JMTek Windows_10
EXITCODE=$(echo "$?")
# if = 0, then successfully attached, 1 = already attached (no-op), 2 - other error, detach and attempt re-attach
while [ $EXITCODE -eq 2 ]
do
  /mnt/user/Common/Lakka_Emulation_Station/detach_device.sh 0x0c76 0x161f microphone JMTek Windows_10
  /mnt/user/Common/Lakka_Emulation_Station/attach_device.sh 0x0c76 0x161f microphone JMTek Windows_10
  EXITCODE=$(echo "$?")
  echo "Exit code attempting to detach and re-attach device: $EXITCODE"
done
