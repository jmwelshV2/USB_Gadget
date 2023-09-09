#!/bin/bash

# Enabling strict error handling
set -e

# Updating package list and installing necessary packages
sudo apt update

# Adding and loading necessary kernel modules
echo "dwc2" | sudo tee -a /etc/modules
if ! lsmod | grep -q "dwc2"; then
    sudo modprobe dwc2
fi

if ! lsmod | grep -q "libcomposite"; then
    sudo modprobe libcomposite
fi

# Moving usb_gadget.sh script to the appropriate location and making it executable
sudo cp usb_gadget.sh /usr/bin/
sudo chmod +x /usr/bin/usb_gadget.sh

# Creating a systemd service to run the script at boot
echo "[Unit]
Description=Setup PCIe card as a USB gadget

[Service]
Type=oneshot
ExecStart=/usr/bin/usb_gadget.sh

[Install]
WantedBy=multi-user.target
" | sudo tee /etc/systemd/system/usb_gadget.service

# Enabling and starting the service to set up the gadget immediately
sudo systemctl daemon-reload
sudo systemctl enable usb_gadget.service
sudo systemctl start usb_gadget.service
