#!/bin/bash

# Install necessary packages
sudo apt update
sudo apt install -y libcomposite

# Load the libcomposite module
sudo modprobe libcomposite

# Create the rpi4_usb.sh script in the /usr/bin/ directory
sudo bash -c 'cat > /usr/bin/rpi4_usb.sh << EOL
#!/bin/bash

# Create and enter the gadget directory
cd /sys/kernel/config/usb_gadget/
mkdir -p pi4_usb_gadget
cd pi4_usb_gadget

# Configure the USB gadget
echo 0x1d6b > idVendor # Linux Foundation
echo 0x0104 > idProduct # Multifunction Composite Gadget
echo 0x0100 > bcdDevice
echo 0x0200 > bcdUSB

# Create English (US) locale
mkdir -p strings/0x409

echo "pi4_usb_gadget" > strings/0x409/serialnumber
echo "Raspberry Pi" > strings/0x409/manufacturer
echo "Pi4 USB Gadget" > strings/0x409/product

# Create configuration
mkdir -p configs/c.1/strings/0x409
echo "Config 1: Mass Storage" > configs/c.1/strings/0x409/configuration

# Find all drives excluding the root drive and create a function for each
root_drive=\$(mount | grep ' on / type' | awk '{print \$1}')
for drive in \$(ls /dev/ | grep '^sd[a-z][0-9]*\$'); do
    if [ "/dev/\$drive" != "\$root_drive" ]; then
        # Create a function for mass storage
        mkdir -p functions/mass_storage.\$drive
        echo 1 > functions/mass_storage.\$drive/stall
        echo 0 > functions/mass_storage.\$drive/lun.0/removable
        echo /dev/\$drive > functions/mass_storage.\$drive/lun.0/file
        # Link the mass storage function to the configuration
        ln -s functions/mass_storage.\$drive configs/c.1/
    fi
done

# Bind the USB gadget to UDC
ls /sys/class/udc > UDC
EOL'

# Make the script executable
sudo chmod +x /usr/bin/rpi4_usb.sh

# Create a systemd service to run the script at boot
echo "[Unit]
Description=Setup Raspberry Pi as a USB gadget

[Service]
Type=oneshot
ExecStart=/usr/bin/rpi4_usb.sh

[Install]
WantedBy=multi-user.target
" | sudo tee /etc/systemd/system/rpi4_usb.service

# Start the service and enable it to run at boot
sudo systemctl daemon-reload
sudo systemctl enable rpi4_usb.service

# Now start the service to set up the gadget immediately
sudo systemctl start rpi4_usb.service
