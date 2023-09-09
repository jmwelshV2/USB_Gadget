#!/bin/bash

# Enabling strict error handling
set -e

# Moving to the usb_gadget directory and setting up the gadget
cd /sys/kernel/config/usb_gadget/
mkdir -p pcie_usb_gadget
cd pcie_usb_gadget

# Configuring the USB gadget with the specified vendor and product IDs, etc.
echo 0x1d6b > idVendor # Linux Foundation
echo 0x0104 > idProduct # Multifunction Composite Gadget
echo 0x0100 > bcdDevice
echo 0x0200 > bcdUSB

# Creating English (US) locale and defining the gadget's strings
mkdir -p strings/0x409
echo "fedcba9876543210" > strings/0x409/serialnumber
echo "Esoteric Technologies" > strings/0x409/manufacturer
echo "Esoteric USB Device" > strings/0x409/product

# Creating a configuration for the gadget
mkdir -p configs/c.1/strings/0x409
echo "Config 1: Mass Storage" > configs/c.1/strings/0x409/configuration

# Identifying the root drive using a reliable method
root_drive=$(df / | tail -1 | awk '{print $1}')

# Finding all drives excluding the root drive and creating a function for each
for drive in $(ls /dev/ | grep '^sd[a-z][0-9]*$'); do
    if [ "/dev/$drive" != "$root_drive" ]; then
        # Creating a function for mass storage and linking it to the configuration
        mkdir -p functions/mass_storage.$drive
        echo 1 > functions/mass_storage.$drive/stall
        echo 0 > functions/mass_storage.$drive/lun.0/removable
        echo /dev/$drive > functions/mass_storage.$drive/lun.0/file
        ln -s functions/mass_storage.$drive configs/c.1/
    fi
done

# Binding the USB gadget to the UDC driver
ls /sys/class/udc > UDC
