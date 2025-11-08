# Linux VPS Swap Management Script

[中文文档](README_CN.md) | English

A one-click script to easily add, remove, and manage swap space on Linux VPS servers.

## Features

- ✅ Add swap space with customizable sizes (1GB, 2GB, 4GB, 8GB, or custom)
- ✅ Remove swap space completely
- ✅ View current swap status
- ✅ Install script to system for easy access
- ✅ Automatic persistence (survives reboots)
- ✅ Optimized swap settings (swappiness & cache pressure)
- ✅ Interactive menu interface
- ✅ Command-line arguments support
- ✅ Color-coded output for better readability

## Quick Start

### One-Click Installation & Run

```bash
bash <(curl -Ls https://raw.githubusercontent.com/uniquMonte/swap-setup/main/install.sh)
```

This will launch the interactive menu where you can:
- Add/Create swap space
- Remove swap space
- Install the script permanently
- Uninstall the script

### Install to System

To install the script permanently to your system:

```bash
# Run the installer
bash <(curl -Ls https://raw.githubusercontent.com/uniquMonte/swap-setup/main/install.sh)

# Then select option 3 "Install Script to System"
# Or use command line argument:
bash <(curl -Ls https://raw.githubusercontent.com/uniquMonte/swap-setup/main/install.sh) install
```

After installation, you can run it anytime with:

```bash
swap-manager
```

## Usage

### Interactive Menu

Run the script without arguments to launch the interactive menu:

```bash
sudo swap-manager
# or
sudo bash install.sh
```

### Command-Line Arguments

The script also supports direct command-line usage:

```bash
# Add swap (interactive size selection)
sudo swap-manager add

# Remove swap
sudo swap-manager remove

# Show swap status
sudo swap-manager status

# Install script to system
sudo swap-manager install

# Uninstall script from system
sudo swap-manager uninstall
```

## How It Works

### Adding Swap

1. **Creates a swap file** at `/swapfile`
2. **Sets proper permissions** (600)
3. **Formats as swap space**
4. **Enables the swap**
5. **Makes it persistent** by adding to `/etc/fstab`
6. **Optimizes settings**:
   - `vm.swappiness=10` (uses swap only when needed)
   - `vm.vfs_cache_pressure=50` (balanced cache retention)

### Removing Swap

1. **Disables the swap** space
2. **Removes the swap file**
3. **Cleans up** `/etc/fstab` entry

## Requirements

- Linux-based operating system
- Root privileges (sudo)
- `bash` shell
- `curl` (for one-click installation)

## Swap Size Recommendations

| RAM Size | Recommended Swap |
|----------|------------------|
| 512 MB   | 1 GB             |
| 1 GB     | 2 GB             |
| 2 GB     | 2-4 GB           |
| 4 GB     | 2-4 GB           |
| 8 GB+    | 2-4 GB           |

**Note**: For VPS servers, swap is particularly useful to prevent out-of-memory errors during memory spikes.

## What is Swap?

Swap space is a portion of hard drive storage that acts as virtual memory when your system's RAM is full. It helps:
- Prevent out-of-memory crashes
- Handle memory spikes
- Improve system stability on low-memory systems

## System Compatibility

Tested and working on:
- Ubuntu (18.04, 20.04, 22.04, 24.04)
- Debian (9, 10, 11, 12)
- CentOS / Rocky Linux / AlmaLinux (7, 8, 9)
- Fedora
- Other Linux distributions with systemd

## Troubleshooting

### Permission Denied

Make sure you're running with root privileges:

```bash
sudo bash install.sh
```

### Disk Space Issues

Check available disk space before creating swap:

```bash
df -h /
```

Ensure you have enough free space for the swap size you want to create.

### Swap Not Persisting After Reboot

Check if the entry exists in `/etc/fstab`:

```bash
cat /etc/fstab | grep swapfile
```

If missing, the script can re-add it when you run "Add/Create Swap" again.

## Security Notes

- The swap file is created with permissions `600` (only readable/writable by root)
- Swap file location: `/swapfile`
- System configuration: `/etc/fstab` and `/etc/sysctl.conf`

## Uninstallation

To completely remove the script and swap:

1. **Remove swap space**: Use option 2 in the menu
2. **Uninstall script**: Use option 4 in the menu

Or use command line:

```bash
sudo swap-manager remove      # Remove swap
sudo swap-manager uninstall   # Remove script
```

## Contributing

Issues and pull requests are welcome at [https://github.com/uniquMonte/swap-setup](https://github.com/uniquMonte/swap-setup)

## License

MIT License - feel free to use and modify as needed.

## Author

**uniquMonte**

- GitHub: [@uniquMonte](https://github.com/uniquMonte)

## Changelog

### Version 1.0.0 (2025-01-08)
- Initial release
- Add/remove swap functionality
- Interactive menu interface
- Command-line arguments support
- Automatic optimization settings
- Install/uninstall script capability
