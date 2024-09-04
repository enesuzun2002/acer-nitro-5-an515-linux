#!/bin/bash

# Check if the user wants to proceed
read -p "Do you want enable echo cancelling and noise suppression for voice? (y/n) " -r
if [[ $REPLY =~ ^[yY]$ ]]; then
    # Copy the config file from script's directory to $HOME/.config/
    mkdir -p $HOME/.config/pipewire/pipewire.conf.d/
    cp ./Audio-Fixes/.config/pipewire/pipewire.conf.d/99-input-echo-cancel.conf $HOME/.config/pipewire/pipewire.conf.d/99-input-echo-cancel.conf > /dev/null 2>&1

    if [ $? -ne 0 ]; then
        echo "Error copying config file!"
    else
        echo "Config file copied successfully."

        echo "Restarting pipewire..."
        systemctl --user restart wireplumber pipewire pipewire-pulse > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "Error restarting pipewire service!"
        else
            echo "Installation completed successfully!"
        fi
    fi
else
    echo "Installation cancelled."
fi

read -p "Do you want to import recommended alsamixer values for mic? (y/n) " -r
if [[ $REPLY =~ ^[yY]$ ]]; then
    echo "Copying files..."
    cp ./Audio-Fixes/.config/asound.state $HOME/.config/asound.state > /dev/null 2>&1

    if [ $? -ne 0 ]; then
        echo "Error copying files!"
        exit 1
    else
        echo "Adding to .profile for loading at each log in..."
        echo -e "\n# Alsamixer recommended settings by enesuzun2002\nalsactl --file $HOME/.config/asound.state restore" >> $HOME/.profile
        if [ $? -ne 0 ]; then
            echo "Error adding to .profile!"
            exit 1
        else

            echo "Installation completed successfully!"
        fi
    fi
else
    echo "Installation cancelled."
fi

read -p "Do you want to add fix for headset-mic? (y/n) " -r
if [[ $REPLY =~ ^[yY]$ ]]; then
    echo "Adding configuration to alsa-base.conf..."
    read -s -p "[sudo] password for $USER: " PASSWORD
    echo
    echo $PASSWORD | sudo -S sh -c 'echo "options snd-hda-intel model=auto,dell-headset-multi" >> /etc/modprobe.d/alsa-base.conf'
    if [ $? -ne 0 ]; then
        echo "Error configuration to alsa-base.conf!"
        exit 1
    else
        echo "Installation completed successfully!"
    fi
else
    echo "Installation cancelled."
fi

read -p "Do you want to disable audio device suspend on idle? (y/n) " -r
if [[ $REPLY =~ ^[yY]$ ]]; then
    echo "Copying files..."
    mkdir -p $HOME/.config/wireplumber/wireplumber.conf.d
    cp ./Audio-Fixes/.config/wireplumber/wireplumber.conf.d/alsa.conf $HOME/.config/wireplumber/wireplumber.conf.d/alsa.conf > /dev/null 2>&1

    if [ $? -ne 0 ]; then
        echo "Error copying files!"
        exit 1
    else
        echo "Adding configuration to alsa-base.conf..."
        read -s -p "[sudo] password for $USER: " PASSWORD
        echo
        echo $PASSWORD | sudo -S sh -c 'echo "options snd-hda-intel power_save=0" >> /etc/modprobe.d/alsa-base.conf'
        if [ $? -ne 0 ]; then
            echo "Error configuration to alsa-base.conf!"
            exit 1
        else
            echo "Installation completed successfully!"
        fi
    fi
else
    echo "Installation cancelled."
fi

read -p "Do you want to enable power saving mode for intel wifi? (y/n) " -r
if [[ $REPLY =~ ^[yY]$ ]]; then
    echo "Copying files..."
    read -s -p "[sudo] password for $USER: " PASSWORD
    echo
    echo $PASSWORD | sudo -S cp ./Wifi-Fixes/etc/modprobe.d/* /etc/modprobe.d/ > /dev/null 2>&1

    if [ $? -ne 0 ]; then
        echo "Error copying files!"
        exit 1
    else
        echo "Installation completed successfully!"
    fi
else
    echo "Installation cancelled."
fi

read -p "Do you want to enable power management script by enesuzun2002? (y/n) " -r
if [[ $REPLY =~ ^[yY]$ ]]; then
    # Copy scripts
    echo "Copying files..."
    read -s -p "[sudo] password for $USER: " PASSWORD
    echo

    # Function to handle sudo commands
    run_sudo() {
        echo $PASSWORD | sudo -S $1 > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "Error: $2"
            exit 1
        fi
    }

    # Copy files and handle errors
    run_sudo "cp ./Power-Management/etc/modules-load.d/* /etc/modules-load.d/" "Failed to copy modules-load.d files."
    run_sudo "cp ./Power-Management/etc/udev/rules.d/* /etc/udev/rules.d/" "Failed to copy udev rules."
    run_sudo "cp ./Power-Management/usr/lib/systemd/system-sleep/00powersave /usr/lib/systemd/system-sleep/00powersave" "Failed to copy system-sleep script."
    run_sudo "cp ./Power-Management/usr/local/bin/* /usr/local/bin/" "Failed to copy local bin scripts."

    # Set required permissions for scripts
    echo "Setting required permissions for scripts..."
    run_sudo "chmod +x /usr/lib/systemd/system-sleep/00powersave" "Failed to set executable permission for 00powersave."
    run_sudo "chmod +x /usr/local/bin/power_save.sh" "Failed to set executable permission for power_save.sh."

    echo "Installation completed successfully!"
else
    echo "Installation cancelled."
fi
