#!/bin/bash

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo or as root."
    exit 1
fi

# Update the system
echo "Updating"
dnf update -y

# Create arrays to store failed installations
failed_installs_packages=()
failed_installs_extensions=()

# Install packages from packages.txt
echo "installing packages"
while read -r package; do
    echo "Installing $package..."
    dnf install -y "$package"
    if [ $? -eq 0 ]; then
        echo "$package installed successfully."
    else
        echo "Failed to install $package. Check for errors."
        failed_installs_packages+=("$package")
    fi
done < packages.txt

# install gnome extensions
echo "installing gnome extensions"
while read -r extension; do
    echo "Installing GNOME extension: $extension..."
    
    # Use gnome-extensions command to install the extension
    gnome-extensions install "$extension"
    
    if [ $? -eq 0 ]; then
        echo "GNOME extension $extension installed successfully."
    else
        echo "Failed to install GNOME extension $extension. Check for errors."
        failed_installs_extensions+=("$extension")
    fi
done < extensions.txt

# set gnome settings
echo "setting gnome settings"
gsettings set org.gnome.shell favorite-apps "['firefox.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Software.desktop', 'org.gnome.Terminal.desktop', 'gnome-system-monitor.desktop']"

# install software that is not in the default repos
echo "Installing software outside of default repos"
read -p "This script will install Tailscale. Do you want to continue? (y/n): " choice
if [[ $choice =~ ^[Yy]$ ]]; then
    # Download and install Tailscale
    sudo dnf install -y dnf-plugins-core
    sudo dnf config-manager --add-repo https://pkgs.tailscale.com/stable/fedora/tailscale.repo
    sudo dnf install -y tailscale

    # Authenticate with your Tailscale account
    # sudo tailscale up

    # Optional: Enable Tailscale to start on boot
    sudo systemctl enable tailscaled

    echo "Tailscale installed successfully!"
else
    echo "Installation aborted."
    failed_installs_packages+=("Tailscale")
fi

# Print the list of failed installations
if [ ${#failed_installs_packages[@]} -eq 0 ]; then
    echo "All package installations completed successfully."
else
    echo "Failed to install the following packages:"
    for failed_package in "${failed_installs_packages[@]}"; do
        echo "- $failed_package"
    done
fi

# Print the list of failed installations
if [ ${#failed_installs_extensions[@]} -eq 0 ]; then
    echo "All extension installations completed successfully."
else
    echo "Failed to install the following GNOME extensions:"
    for failed_extension in "${failed_installs_extensions[@]}"; do
        echo "- $failed_extension"
    done
fi
