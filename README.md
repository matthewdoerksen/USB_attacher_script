# USB_attacher_script

Automatically find and attach USB devices to VMs to avoid manual re-configuration when devices are moved between machines.

Setup
1) Add the user scripts plugin
2) `mkdir /boot/config/plugins/user.scripts/scripts/attach_devices_to_vms`
3) Copy contents of attach_devices_to_vms folder from here to folder above
4) In the user scripts plugin, choose to run the script on a custom schedule (* * * * *) - once a minute
5) Run the script in the background

Notes
---------
Tested to ensure the devices re-attach to the VM:
 - removing the attached devices with the detach script
 - physically unplugging the USB cable and ensuring they re-attach as per the cron job
