#!/bin/bash

# Check if the display manager is SDDM
if [[ $(cat /etc/X11/default-display-manager 2>/dev/null) == "/usr/bin/sddm" ]]; then
    echo "SDDM is the current display manager."
else
    echo "This display manager isn't supported yet!"
    exit 1
fi


# Define the file to modify
FILE="/usr/share/sddm/scripts/Xsetup"

# Define the lines to remove
LINE1="xrandr --setprovideroutputsource modesetting NVIDIA-0"
LINE2="xrandr --auto"

# Script path
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

# Set nvidia gpu as primary on optimus laptops
if [ "$1" == "true" ]; then
    echo "Setting nvidia as primary gpu..."

    read -s -p "[sudo] password for $USER: " PASSWORD
    echo

    # Check if the lines already exist in the file
    if ! grep -Fxq "$LINE1" $FILE; then
        echo "Adding line: $LINE1"
        echo $PASSWORD | sudo -S sh -c "echo '$LINE1' >> '$FILE'"
    fi

    if ! grep -Fxq "$LINE2" $FILE; then
        echo "Adding line: $LINE2"
        echo $PASSWORD | sudo -S sh -c "echo '$LINE2' >> '$FILE'"
    fi

    echo $PASSWORD | sudo -S cp "$SCRIPT_DIR/10-nvidia-drm-outputclass.conf" /etc/X11/xorg.conf.d/10-nvidia-drm-outputclass.conf > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Error copying configuration for X11"
        exit 1
    else
        echo "Nvidia is set as primary gpu successfully!"
    fi



elif [ "$1" == "false" ]; then
    echo "Setting default values..."

    read -s -p "[sudo] password for $USER: " PASSWORD
    echo

    # Use sudo to modify the file, removing the specified lines
    if echo $PASSWORD | sudo -S grep -Fxq "$LINE1" $FILE; then
        echo "Removing line: $LINE1"
        echo $PASSWORD | sudo -S sed -i "\|$LINE1|d" $FILE
    fi

    if echo $PASSWORD | sudo -S grep -Fxq "$LINE2" $FILE; then
        echo "Removing line: $LINE2"
        echo $PASSWORD | sudo -S sed -i "\|$LINE2|d" $FILE
    fi

    echo $PASSWORD | sudo -S rm -f /etc/X11/xorg.conf.d/10-nvidia-drm-outputclass.conf > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Error removing configuration for X11"
        exit 1
    else
        echo "Default values were restored successfully!"
    fi

else
    echo "Invalid argument. Please pass either 'true' or 'false'."
    exit 1
fi
