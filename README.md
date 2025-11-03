# Ultimate Automated Bluetooth Adapter Management for Linux

## Overview

This project provides an **automated solution for managing Bluetooth adapters on Linux**. It prioritizes external USB Bluetooth dongles over internal adapters and ensures internal adapters are disabled whenever an external adapter is present. The system restores internal adapters automatically if no external adapter is detected.

The solution consists of:

* **`manage_internal_bt.sh`** – the main script for detecting and managing Bluetooth adapters.
* **Udev rules** – automatically trigger the script when USB Bluetooth devices are plugged or unplugged.
* Automatic package installation, kernel module loading, and Bluetooth service management.

---

## Features

* Detects internal PCI and USB Bluetooth adapters.
* Detects external USB Bluetooth adapters.
* Automatically disables internal adapters when an external adapter is present.
* Keeps internal adapters enabled when no external adapter exists.
* Works automatically via udev rules when USB adapters are connected or disconnected.
* Installs required packages and firmware if missing.
* Loads necessary kernel modules and starts the Bluetooth service.
* Adds `AutoEnable=true` to `/etc/bluetooth/main.conf` for automatic adapter activation.

---

## Requirements

* Linux system with `systemd`.
* `sudo` privileges.
* `apt` package manager (tested on Debian/Ubuntu-based distributions).
* Internal and/or external Bluetooth adapters (USB or PCI).

---

## Installation

1. **Download or create the setup script**:

```bash
sudo nano setup_bt_manager.sh
```

2. **Paste the setup script** (provided in this repository) and save.

3. **Make the script executable**:

```bash
sudo chmod +x setup_bt_manager.sh
```

4. **Run the setup script**:

```bash
sudo ./setup_bt_manager.sh
```

5. **Reboot** to ensure full Bluetooth service initialization:

```bash
sudo reboot
```

---

## Usage

* The script `manage_internal_bt.sh` is installed at `/usr/local/bin/manage_internal_bt.sh`.
* It can be run manually anytime:

```bash
sudo /usr/local/bin/manage_internal_bt.sh
```

* Automatic execution happens whenever a USB Bluetooth device is plugged or unplugged via udev rules.

---

## File Structure

```
/usr/local/bin/manage_internal_bt.sh   # Main Bluetooth management script
/etc/udev/rules.d/99-internal-bt.rules # Udev rule triggering the script
setup_bt_manager.sh                     # One-time setup script
```

---

## Troubleshooting

* If internal adapters are not blocked, ensure they are correctly detected in the `lsusb` or `lspci` output.
* Check udev logs for script triggers:

```bash
sudo udevadm monitor
```

* Ensure `rfkill` is installed and functional for blocking adapters.

---

## Author

Vishal Chaudhary

Do you want me to do that next?
