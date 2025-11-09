# Linux VPS Swap Setup

One-click script to manage swap space on Linux VPS.

## Install

```bash
bash <(curl -Ls https://raw.githubusercontent.com/uniquMonte/swap-setup/main/install.sh)
```

## Menu Options

```
1) Add/Create Swap
2) Remove Swap
3) Modify Swap Size
4) View Detailed Configuration
5) Refresh Status
0) Exit
```

## Features

### Add/Create Swap

When creating swap space, you can configure:

- **Swap Size**: Choose recommended size or specify custom size (e.g., 1G, 2G, 512M)
- **Swappiness**: Choose from:
  - System Default (60)
  - Recommended (optimized based on your RAM and swap size)
  - Custom value (0-100)
- **Cache Pressure**: Choose from:
  - System Default (100)
  - Recommended (optimized based on your RAM)
  - Custom value (typically 0-200)

The script will display a configuration summary before creating the swap file.

### Modify Swap Size

Modify the size of an existing swap file. The script will automatically optimize swappiness and cache pressure settings based on the new swap size.

### View Detailed Configuration

View comprehensive information about your system, including:
- System resources (RAM, available disk)
- Current swap status and configuration
- Kernel parameters (swappiness, cache pressure)
- Recommended settings for your system

## License

MIT
