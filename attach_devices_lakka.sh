#!/bin/bash

# attach SNES controllers
/mnt/user/Common/Lakka_Emulation_Station/attach_device.sh 0x0079 0x0011 snes_controller Dragon Lakka
EXITCODE=$(echo "$?")
# if = 0, then successfully attached, 1 = already attached (no-op), 2 - other error, detach and attempt re-attach
while [ $EXITCODE -eq 2 ]
do
  /mnt/user/Common/Lakka_Emulation_Station/detach_device.sh 0x0079 0x0011 snes_controller Dragon Lakka
  /mnt/user/Common/Lakka_Emulation_Station/attach_device.sh 0x0079 0x0011 snes_controller Dragon Lakka
  EXITCODE=$(echo "$?")
  echo "Exit code attempting to detach and re-attach device: $EXITCODE"
done
