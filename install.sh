#!/bin/bash

#==============================================================================
# Swap Management Script for Linux VPS
#
# Description: A one-click script to add, remove, and manage swap space
# Author: uniquMonte
# Repository: https://github.com/uniquMonte/swap-setup
#==============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Swap file location
SWAP_FILE="/swapfile"
SCRIPT_INSTALL_PATH="/usr/local/bin/swap-manager"

#==============================================================================
# Helper Functions
#==============================================================================

print_banner() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║         Linux VPS Swap Management Script                  ║"
    echo "║         Author: uniquMonte                                 ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        echo "Please use: sudo $0"
        exit 1
    fi
}

# Get current swap information
get_swap_info() {
    local swap_total=$(free -h | grep Swap | awk '{print $2}')
    local swap_used=$(free -h | grep Swap | awk '{print $3}')
    local swap_free=$(free -h | grep Swap | awk '{print $4}')

    echo -e "${BLUE}Current Swap Status:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Total: $swap_total"
    echo "Used:  $swap_used"
    echo "Free:  $swap_free"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [ -f "$SWAP_FILE" ]; then
        local swap_size=$(ls -lh $SWAP_FILE | awk '{print $5}')
        echo "Swap File: $SWAP_FILE ($swap_size)"
    fi
    echo ""
}

# Check available disk space
check_disk_space() {
    local available_gb=$(df -BG / | tail -1 | awk '{print $4}' | sed 's/G//')
    echo $available_gb
}

# Get total RAM in MB
get_ram_mb() {
    local ram_mb=$(free -m | grep Mem | awk '{print $2}')
    echo $ram_mb
}

# Calculate recommended swap size based on RAM
get_recommended_swap() {
    local ram_mb=$(get_ram_mb)
    local available_gb=$(check_disk_space)
    local recommended=""

    # Recommendation logic for VPS:
    # RAM < 1GB (1024MB): 2GB swap
    # RAM 1-2GB: 2GB swap
    # RAM 2-4GB: 2GB swap
    # RAM 4-8GB: 4GB swap
    # RAM > 8GB: 4GB swap

    if [ $ram_mb -lt 1024 ]; then
        recommended="2G"
    elif [ $ram_mb -lt 2048 ]; then
        recommended="2G"
    elif [ $ram_mb -lt 4096 ]; then
        recommended="2G"
    elif [ $ram_mb -lt 8192 ]; then
        recommended="4G"
    else
        recommended="4G"
    fi

    # Check if we have enough disk space
    local rec_size_gb=$(echo $recommended | sed 's/G//')
    if [ $available_gb -lt $((rec_size_gb + 2)) ]; then
        # Not enough space, recommend 1GB
        recommended="1G"
    fi

    echo $recommended
}

#==============================================================================
# Swap Management Functions
#==============================================================================

# Create swap
create_swap() {
    # Get system information
    local ram_mb=$(get_ram_mb)
    local ram_gb=$(echo "scale=1; $ram_mb / 1024" | bc)
    local available_gb=$(check_disk_space)
    local recommended=$(get_recommended_swap)

    echo ""
    echo -e "${BLUE}System Information:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "RAM:             ${ram_gb} GB"
    echo "Available Disk:  ${available_gb} GB"
    echo "Recommended:     ${GREEN}${recommended}${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${BLUE}Enter swap size (or press Enter for recommended ${recommended}):${NC}"
    echo "Examples: 1G, 2G, 512M"
    echo "Enter 0 to cancel"
    echo ""

    read -p "Swap size [${recommended}]: " swap_size

    # If empty, use recommended
    if [ -z "$swap_size" ]; then
        swap_size=$recommended
        print_success "Using recommended size: $swap_size"
    elif [ "$swap_size" = "0" ]; then
        print_info "Operation cancelled"
        return 0
    else
        # Validate custom size
        if [[ ! $swap_size =~ ^[0-9]+[MG]$ ]]; then
            print_error "Invalid format. Please use format like: 512M or 2G"
            return 1
        fi
    fi

    # Check if swap already exists
    if [ -f "$SWAP_FILE" ]; then
        print_warning "Swap file already exists at $SWAP_FILE"
        read -p "Do you want to remove it and create a new one? (y/n): " confirm
        if [[ $confirm != "y" && $confirm != "Y" ]]; then
            print_info "Operation cancelled"
            return 0
        fi
        remove_swap
    fi

    # Check available disk space
    local available=$(check_disk_space)
    local required=$(echo $swap_size | sed 's/G//' | sed 's/M//')

    print_info "Creating ${swap_size} swap file..."
    echo ""

    # Create swap file
    if ! dd if=/dev/zero of=$SWAP_FILE bs=1M count=$(echo $swap_size | sed 's/G/*1024/' | sed 's/M//' | bc) status=progress 2>/dev/null; then
        print_error "Failed to create swap file"
        return 1
    fi

    # Set proper permissions
    print_info "Setting permissions..."
    chmod 600 $SWAP_FILE

    # Set up swap space
    print_info "Setting up swap space..."
    if ! mkswap $SWAP_FILE > /dev/null 2>&1; then
        print_error "Failed to set up swap space"
        rm -f $SWAP_FILE
        return 1
    fi

    # Enable swap
    print_info "Enabling swap..."
    if ! swapon $SWAP_FILE; then
        print_error "Failed to enable swap"
        rm -f $SWAP_FILE
        return 1
    fi

    # Make swap permanent
    if ! grep -q "$SWAP_FILE" /etc/fstab; then
        print_info "Adding swap to /etc/fstab for persistence..."
        echo "$SWAP_FILE none swap sw 0 0" >> /etc/fstab
    fi

    # Optimize swap settings
    print_info "Optimizing swap settings..."

    # Set swappiness (how aggressively the kernel swaps)
    if ! grep -q "vm.swappiness" /etc/sysctl.conf; then
        echo "vm.swappiness=10" >> /etc/sysctl.conf
    else
        sed -i 's/vm.swappiness=.*/vm.swappiness=10/' /etc/sysctl.conf
    fi

    # Set cache pressure
    if ! grep -q "vm.vfs_cache_pressure" /etc/sysctl.conf; then
        echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf
    else
        sed -i 's/vm.vfs_cache_pressure=.*/vm.vfs_cache_pressure=50/' /etc/sysctl.conf
    fi

    # Apply settings
    sysctl -p > /dev/null 2>&1

    echo ""
    print_success "Swap space created successfully!"
    echo ""
    get_swap_info
}

# Remove swap
remove_swap() {
    if [ ! -f "$SWAP_FILE" ]; then
        print_warning "No swap file found at $SWAP_FILE"
        return 0
    fi

    print_warning "This will remove the swap space."
    read -p "Are you sure? (y/n): " confirm

    if [[ $confirm != "y" && $confirm != "Y" ]]; then
        print_info "Operation cancelled"
        return 0
    fi

    print_info "Disabling swap..."
    swapoff $SWAP_FILE 2>/dev/null

    print_info "Removing swap file..."
    rm -f $SWAP_FILE

    print_info "Removing from /etc/fstab..."
    sed -i "\|$SWAP_FILE|d" /etc/fstab

    print_success "Swap removed successfully!"
    echo ""
    get_swap_info
}

# Install script to system
install_script() {
    if [ -f "$SCRIPT_INSTALL_PATH" ]; then
        print_info "Script already installed at $SCRIPT_INSTALL_PATH"
        return 0
    fi

    print_info "Installing script to $SCRIPT_INSTALL_PATH..."
    cp "$0" "$SCRIPT_INSTALL_PATH" 2>/dev/null || {
        # If $0 is not a file (piped from curl), download it
        curl -Ls https://raw.githubusercontent.com/uniquMonte/swap-setup/main/install.sh -o "$SCRIPT_INSTALL_PATH"
    }
    chmod +x "$SCRIPT_INSTALL_PATH"

    print_success "Script installed successfully!"
    print_info "You can now run: swap-manager"
}

# Uninstall script
uninstall_script() {
    print_warning "This will remove the swap-manager script from your system."
    print_info "Note: This will NOT remove the swap space. Use option 2 to remove swap first if needed."
    read -p "Are you sure? (y/n): " confirm

    if [[ $confirm != "y" && $confirm != "Y" ]]; then
        print_info "Operation cancelled"
        return 0
    fi

    if [ -f "$SCRIPT_INSTALL_PATH" ]; then
        rm -f "$SCRIPT_INSTALL_PATH"
        print_success "Script uninstalled successfully!"
    else
        print_warning "Script not found at $SCRIPT_INSTALL_PATH"
    fi
}

#==============================================================================
# Main Menu
#==============================================================================

show_menu() {
    clear
    print_banner
    get_swap_info

    echo -e "${BLUE}Menu:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "1) Add/Create Swap"
    echo "2) Remove Swap"
    echo "3) Install Script to System"
    echo "4) Uninstall Script"
    echo "5) Refresh Status"
    echo "0) Exit"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

main() {
    check_root

    # If run with arguments, handle them
    if [ $# -gt 0 ]; then
        case $1 in
            install)
                install_script
                exit 0
                ;;
            uninstall)
                uninstall_script
                exit 0
                ;;
            add)
                create_swap
                exit 0
                ;;
            remove)
                remove_swap
                exit 0
                ;;
            status)
                print_banner
                get_swap_info
                exit 0
                ;;
            *)
                echo "Usage: $0 {install|uninstall|add|remove|status}"
                exit 1
                ;;
        esac
    fi

    # Interactive menu
    while true; do
        show_menu
        read -p "Enter your choice [0-5]: " choice

        case $choice in
            1)
                create_swap
                read -p "Press Enter to continue..."
                ;;
            2)
                remove_swap
                read -p "Press Enter to continue..."
                ;;
            3)
                install_script
                read -p "Press Enter to continue..."
                ;;
            4)
                uninstall_script
                read -p "Press Enter to continue..."
                exit 0
                ;;
            5)
                continue
                ;;
            0)
                print_info "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid choice"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Run main function
main "$@"
