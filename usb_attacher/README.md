# USB_attacher_script

Automatically find and attach USB devices to KVM VMs to avoid manual re-configuration when devices are attached/detached. Does NOT handle attaching the same device to multiple machines.

Setup
1) Add the user scripts plugin
2) `mkdir /boot/config/plugins/user.scripts/scripts/attach_devices_to_vms`
3) Copy contents of attach_devices_to_vms folder from here to folder above
4) In the user scripts plugin, choose to run the script on a custom schedule (* * * * *) - once a minute
5) Run the script in the background
   5.1) <path to attach_devices_<VM>.sh> <path to scripts dir>
