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

# Show detailed swap configuration
show_swap_config() {
    clear
    print_banner

    # System information
    local ram_mb=$(get_ram_mb)
    local available_gb=$(check_disk_space)

    # Format RAM display (use MB if < 1GB, otherwise GB)
    local ram_display
    if [ $ram_mb -lt 1024 ]; then
        ram_display="${ram_mb} MB"
    else
        local ram_gb=$(echo "scale=1; $ram_mb / 1024" | bc)
        ram_display="${ram_gb} GB"
    fi

    echo -e "${BLUE}System Resources:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "RAM:             ${ram_display}"
    echo -e "Available Disk:  ${available_gb} GB"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Swap status
    local swap_total=$(free -h | grep Swap | awk '{print $2}')
    local swap_used=$(free -h | grep Swap | awk '{print $3}')
    local swap_free=$(free -h | grep Swap | awk '{print $4}')

    echo -e "${BLUE}Swap Status:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Total:           $swap_total"
    echo "Used:            $swap_used"
    echo "Free:            $swap_free"

    if [ -f "$SWAP_FILE" ]; then
        local swap_size=$(ls -lh $SWAP_FILE | awk '{print $5}')
        echo "Swap File:       $SWAP_FILE ($swap_size)"

        # Check if in fstab
        if grep -q "$SWAP_FILE" /etc/fstab 2>/dev/null; then
            echo -e "Persistence:     ${GREEN}Enabled${NC} (in /etc/fstab)"
        else
            echo -e "Persistence:     ${YELLOW}Not enabled${NC}"
        fi
    else
        echo -e "Status:          ${YELLOW}No swap file configured${NC}"
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Kernel parameters
    echo -e "${BLUE}Kernel Parameters:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Get current swappiness
    local current_swappiness=$(cat /proc/sys/vm/swappiness 2>/dev/null || echo "N/A")
    local recommended_swappiness=$(get_recommended_swappiness)

    if [ "$current_swappiness" = "$recommended_swappiness" ]; then
        echo -e "Swappiness:      ${GREEN}$current_swappiness${NC} (optimal)"
    elif [ "$current_swappiness" = "N/A" ]; then
        echo -e "Swappiness:      ${YELLOW}Not set${NC} (recommended: $recommended_swappiness)"
    else
        echo -e "Swappiness:      $current_swappiness (recommended: ${GREEN}$recommended_swappiness${NC})"
    fi

    # Get current cache pressure
    local cache_pressure=$(cat /proc/sys/vm/vfs_cache_pressure 2>/dev/null || echo "N/A")
    if [ "$cache_pressure" = "50" ]; then
        echo -e "Cache Pressure:  ${GREEN}$cache_pressure${NC} (optimal)"
    elif [ "$cache_pressure" = "N/A" ]; then
        echo -e "Cache Pressure:  ${YELLOW}Not set${NC} (recommended: 50)"
    else
        echo -e "Cache Pressure:  $cache_pressure (recommended: ${GREEN}50${NC})"
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Recommendations
    local recommended_swap=$(get_recommended_swap)
    echo -e "${BLUE}Recommendations:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "Swap Size:       ${GREEN}$recommended_swap${NC}"
    echo -e "Swappiness:      ${GREEN}$recommended_swappiness${NC}"
    echo -e "Cache Pressure:  ${GREEN}50${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
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
    local swap_mb=0

    # Conservative swap recommendation for VPS:
    # RAM < 1GB: 1GB swap (minimum practical size)
    # RAM 1-8GB: 2GB swap (practical size for most VPS)
    # RAM > 8GB: 1GB swap (high RAM systems rarely need swap)

    if [ $ram_mb -lt 1024 ]; then
        # For systems with less than 1GB RAM: recommend 1GB
        swap_mb=1024
    elif [ $ram_mb -le 8192 ]; then
        # For systems with 1-8GB RAM: recommend 2GB (practical and conservative)
        swap_mb=2048
    else
        # For systems with more than 8GB RAM: recommend 1GB (minimal swap for emergency)
        swap_mb=1024
    fi

    # Convert MB to GB (round up)
    local swap_gb=$(( (swap_mb + 1023) / 1024 ))

    # Cap at 8GB maximum (no VPS needs more than 8GB swap)
    if [ $swap_gb -gt 8 ]; then
        swap_gb=8
    fi

    # Ensure minimum of 1GB
    if [ $swap_gb -lt 1 ]; then
        swap_gb=1
    fi

    # Check if we have enough disk space (need at least swap + 2GB free)
    if [ $available_gb -lt $((swap_gb + 2)) ]; then
        # Reduce swap size to fit available space
        swap_gb=$((available_gb - 2))
        if [ $swap_gb -lt 1 ]; then
            swap_gb=1
        fi
    fi

    echo "${swap_gb}G"
}

# Calculate optimal swappiness based on RAM
get_recommended_swappiness() {
    local ram_mb=$(get_ram_mb)
    local swappiness=10

    # Optimal swappiness for VPS based on RAM:
    # RAM < 1GB: 60 (default, needs more swap usage)
    # RAM 1-2GB: 40 (moderate swap usage)
    # RAM 2-4GB: 20 (reduced swap usage)
    # RAM 4-8GB: 10 (minimal swap usage)
    # RAM > 8GB: 5 (very minimal swap usage)

    if [ $ram_mb -lt 1024 ]; then
        swappiness=60
    elif [ $ram_mb -lt 2048 ]; then
        swappiness=40
    elif [ $ram_mb -lt 4096 ]; then
        swappiness=20
    elif [ $ram_mb -lt 8192 ]; then
        swappiness=10
    else
        swappiness=5
    fi

    echo $swappiness
}

#==============================================================================
# Swap Management Functions
#==============================================================================

# Create swap
create_swap() {
    # Get system information
    local ram_mb=$(get_ram_mb)
    local available_gb=$(check_disk_space)
    local recommended=$(get_recommended_swap)

    # Format RAM display (use MB if < 1GB, otherwise GB)
    local ram_display
    if [ $ram_mb -lt 1024 ]; then
        ram_display="${ram_mb} MB"
    else
        local ram_gb=$(echo "scale=1; $ram_mb / 1024" | bc)
        ram_display="${ram_gb} GB"
    fi

    echo ""
    echo -e "${BLUE}System Information:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "RAM:             ${ram_display}"
    echo -e "Available Disk:  ${available_gb} GB"
    echo -e "Recommended:     ${GREEN}${recommended}${NC}"
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

    # Get optimal swappiness for this system
    local swappiness=$(get_recommended_swappiness)

    # Set swappiness (how aggressively the kernel swaps)
    if ! grep -q "vm.swappiness" /etc/sysctl.conf; then
        echo "vm.swappiness=$swappiness" >> /etc/sysctl.conf
    else
        sed -i "s/vm.swappiness=.*/vm.swappiness=$swappiness/" /etc/sysctl.conf
    fi

    # Set cache pressure
    if ! grep -q "vm.vfs_cache_pressure" /etc/sysctl.conf; then
        echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf
    else
        sed -i 's/vm.vfs_cache_pressure=.*/vm.vfs_cache_pressure=50/' /etc/sysctl.conf
    fi

    # Apply settings
    sysctl -p > /dev/null 2>&1

    print_info "Swappiness set to $swappiness (optimized for ${ram_display} RAM)"

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

# Update script to latest version
update_script() {
    print_info "Checking for updates..."

    local temp_file="/tmp/swap-setup-install.sh"
    local github_url="https://raw.githubusercontent.com/uniquMonte/swap-setup/main/install.sh"

    # Download latest version
    if ! curl -Ls "$github_url" -o "$temp_file"; then
        print_error "Failed to download update from GitHub"
        return 1
    fi

    # Verify downloaded file is valid
    if ! bash -n "$temp_file" 2>/dev/null; then
        print_error "Downloaded file is not a valid bash script"
        rm -f "$temp_file"
        return 1
    fi

    print_success "Latest version downloaded successfully"

    # Update current script if running from a file
    if [ -f "$0" ] && [ "$0" != "/dev/stdin" ]; then
        print_info "Updating current script..."
        cp "$temp_file" "$0"
        chmod +x "$0"
        print_success "Current script updated"
    fi

    # Update installed version if exists
    if [ -f "$SCRIPT_INSTALL_PATH" ]; then
        print_info "Updating installed version at $SCRIPT_INSTALL_PATH..."
        cp "$temp_file" "$SCRIPT_INSTALL_PATH"
        chmod +x "$SCRIPT_INSTALL_PATH"
        print_success "Installed version updated"
    fi

    # Clean up
    rm -f "$temp_file"

    echo ""
    print_success "Update completed successfully!"
    print_info "Please restart the script to use the latest version"
    echo ""

    read -p "Press Enter to exit..."
    exit 0
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
    echo "3) View Detailed Configuration"
    echo "4) Update Script"
    echo "5) Uninstall Script"
    echo "6) Refresh Status"
    echo "0) Exit"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
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
            config|show)
                show_swap_config
                exit 0
                ;;
            update|upgrade)
                update_script
                exit 0
                ;;
            *)
                echo "Usage: $0 {install|uninstall|add|remove|status|config|update}"
                exit 1
                ;;
        esac
    fi

    # Interactive menu
    while true; do
        show_menu
        read -p "Enter your choice [0-6] (or press Enter to exit): " choice

        # Default to 0 (Exit) if user presses Enter without input
        choice=${choice:-0}

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
                show_swap_config
                read -p "Press Enter to continue..."
                ;;
            4)
                update_script
                ;;
            5)
                uninstall_script
                read -p "Press Enter to continue..."
                exit 0
                ;;
            6)
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
