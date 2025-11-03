#!/bin/bash
# Ultimate Automated Bluetooth Adapter Management Setup
# Creates script, sets permissions, adds udev rules, installs packages, and prioritizes external BT adapters
# Author: ChatGPT

# Variables
DIR_PATH="/usr/local/bin"
SCRIPT_NAME="manage_internal_bt.sh"
SCRIPT_PATH="$DIR_PATH/$SCRIPT_NAME"
UDEV_RULE_PATH="/etc/udev/rules.d/99-internal-bt.rules"

echo "=== Step 0: Create directory if it doesn't exist ==="
sudo mkdir -p "$DIR_PATH"

echo "=== Step 1: Create/manage the internal Bluetooth management script ==="
sudo tee "$SCRIPT_PATH" > /dev/null <<'EOF'
#!/bin/bash

# Ultimate Automated Bluetooth Adapter Management Script for Linux
# Automatically disables internal adapters if an external USB dongle is present
# Keeps internal adapters enabled if no external adapter exists
# Author: ChatGPT

echo "=== Step 1: Check Bluetooth hardware ==="
echo "USB Bluetooth devices:"
lsusb | grep -i bluetooth
echo "PCI network cards (potential Bluetooth):"
lspci | grep -i network
echo "RFKill status:"
rfkill list
sudo rfkill unblock bluetooth

echo "=== Step 2: Install required packages ==="
sudo apt update
sudo apt install -y bluez blueman firmware-iwlwifi firmware-realtek

echo "=== Step 3: Enable and start Bluetooth service ==="
sudo systemctl enable bluetooth
sudo systemctl start bluetooth
sudo systemctl status bluetooth | grep Active

echo "=== Step 4: Load kernel modules ==="
sudo modprobe btusb
sudo modprobe bluetooth
echo "Loaded Bluetooth modules:"
lsmod | grep bluetooth

echo "=== Step 5: Set AutoEnable=true in Bluetooth config ==="
if ! grep -q "AutoEnable=true" /etc/bluetooth/main.conf; then
    sudo sed -i '/\[General\]/a AutoEnable=true' /etc/bluetooth/main.conf
    echo "AutoEnable=true added to /etc/bluetooth/main.conf"
fi
sudo systemctl restart bluetooth

echo "=== Step 6: List Bluetooth adapters ==="
bluetoothctl list

echo "=== Step 7: Detect internal and external adapters ==="
# Detect internal PCI adapters
INTERNAL_PCI=$(lspci | grep -i bluetooth | awk '{print $1}')
# Detect USB adapters
ALL_USB=$(lsusb | grep -i bluetooth | awk '{print $6}')
# Assume Bus 001 devices are external USB dongles
EXTERNAL_USB=$(lsusb | grep -i bluetooth | grep "Bus 001" | awk '{print $6}')
# Internal USB = all USB minus external USB
INTERNAL_USB=$(comm -23 <(echo "$ALL_USB" | sort) <(echo "$EXTERNAL_USB" | sort))

echo "Internal PCI adapters: $INTERNAL_PCI"
echo "Internal USB adapters: $INTERNAL_USB"
echo "External USB adapters: $EXTERNAL_USB"

# Function to disable internal USB adapter via udev
disable_internal_usb() {
    local IDVENDOR=$1
    local IDPRODUCT=$2
    UDEV_RULE="/etc/udev/rules.d/81-bluetooth-internal-disable.rules"
    sudo bash -c "echo 'ACTION==\"add\", SUBSYSTEM==\"usb\", ATTR{idVendor}==\"$IDVENDOR\", ATTR{idProduct}==\"$IDPRODUCT\", TEST==\"authorized\", ATTR{authorized}=0' >> $UDEV_RULE"
    echo "Udev rule added to disable internal adapter $IDVENDOR:$IDPRODUCT"
}

# Main logic: external adapter detected?
if [ ! -z "$EXTERNAL_USB" ]; then
    echo "External adapter detected. Prioritizing external adapter..."

    # Remove old udev rules
    sudo rm -f /etc/udev/rules.d/81-bluetooth-internal-disable.rules

    # Disable all internal USB adapters
    for DEV in $INTERNAL_USB; do
        IDVENDOR=$(echo $DEV | cut -d: -f1)
        IDPRODUCT=$(echo $DEV | cut -d: -f2)
        disable_internal_usb $IDVENDOR $IDPRODUCT
    done

    # Disable internal PCI adapters via rfkill
    if [ ! -z "$INTERNAL_PCI" ]; then
        echo "Blocking internal PCI Bluetooth adapters..."
        for DEV in $(rfkill list | grep -i bluetooth | awk '{print $1}'); do
            sudo rfkill block $DEV
        done
    fi

    # Reload udev rules
    sudo udevadm control --reload
    sudo udevadm trigger
else
    echo "No external adapter detected. Internal adapters remain active."
fi

echo "=== Step 8: Dynamic device prioritization ==="
echo "Any time an external adapter is plugged in, internal adapters will automatically be disabled."
echo "This is handled by udev rules and rfkill."

echo "=== Done! ==="
echo "Reboot your system to apply changes. Your external Bluetooth adapter will now take priority over internal ones automatically."
EOF

echo "=== Step 2: Make the script executable ==="
sudo chmod +x "$SCRIPT_PATH"

echo "=== Step 3: Create udev rule to trigger script automatically ==="
sudo tee "$UDEV_RULE_PATH" > /dev/null <<EOF
ACTION=="add|remove", SUBSYSTEM=="usb", ATTR{idVendor}!="", ATTR{idProduct}!="", RUN+="$SCRIPT_PATH"
EOF

echo "=== Step 4: Reload udev rules ==="
sudo udevadm control --reload
sudo udevadm trigger

echo "=== Setup Complete ==="
echo "Run $SCRIPT_PATH anytime or plug/unplug a USB Bluetooth adapter to test automatic behavior."
