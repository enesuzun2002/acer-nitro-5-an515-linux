#!/bin/bash

RNNOISE_VER=v1.10

# Check if the user wants to proceed
read -p "Do you want to download and install noise suppression and echo canceller for voice? (y/n) " -r
if [[ $REPLY =~ ^[yY]$ ]]; then
    # Download the file from GitHub
    echo "Downloading the file..."
    wget https://github.com/werman/noise-suppression-for-voice/releases/download/$RNNOISE_VER/linux-rnnoise.zip > /dev/null 2>&1

    if [ $? -ne 0 ]; then
        echo "Error downloading the file!"
        exit 1
    else
        echo "Downloaded successfully."

        # Unzip the downloaded file to /tmp directory
        echo "Unzipping the file..."
        unzip linux-rnnoise.zip -d /tmp > /dev/null 2>&1

        if [ $? -ne 0 ]; then
            echo "Error unzipping the file!"
            rm linux-rnnoise.zip
            exit 1
        else
            echo "Unzipped successfully."

            # Copy the contents of /tmp/rnnoise folder to $HOME/.local/share/enesuzun2002 directory
            echo "Copying files..."
            mkdir -p $HOME/.local/share/enesuzun2002/linux-rnnoise
            cp -r /tmp/linux-rnnoise/* $HOME/.local/share/enesuzun2002/linux-rnnoise > /dev/null 2>&1

            if [ $? -ne 0 ]; then
                echo "Error copying files!"
                rm -rf linux-rnnoise.zip /tmp/linux-rnnoise
                exit 1
            else
                echo "Copied successfully."

                # Copy the config file from script's directory to $HOME/.local/share/enesuzun2002 directory
                mkdir -p $HOME/.config/pipewire/pipewire.conf.d/
                cp ./Audio-Fixes/.config/pipewire/pipewire.conf.d/98-input-echo-cancel.conf $HOME/.config/pipewire/pipewire.conf.d/98-input-echo-cancel.conf > /dev/null 2>&1
                cp ./Audio-Fixes/.config/pipewire/pipewire.conf.d/99-input-denoising.conf $HOME/.config/pipewire/pipewire.conf.d/99-input-denoising.conf > /dev/null 2>&1

                if [ $? -ne 0 ]; then
                    echo "Error copying config file!"
                    rm linux-rnnoise.zip /tmp/rnnoise.zip /tmp/rnnoise
                    exit 1
                else
                    echo "Config file copied successfully."

                    # Clean up
                    rm linux-rnnoise.zip
                    rm -rf /tmp/rnnoise > /dev/null 2>&1

                    if [ $? -ne 0 ]; then
                        echo "Error cleaning up!"
                        exit 1
                    else
                        systemctl --user restart pipewire.service > /dev/null 2>&1
                        if [ $? -ne 0 ]; then
                            echo "Error restarting pipewire service!"
                            exit 1
                        else
                            echo "Installation completed successfully!"
                        fi
                    fi
                fi
            fi
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
    echo $PASSWORD | sudo -S sh -c 'echo -e "options snd-hda-intel model=auto,dell-headset-multi" >> /etc/modprobe.d/alsa-base.conf'
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
        echo $PASSWORD | sudo -S sh -c 'echo -e "options snd-hda-intel power_save=0" >> /etc/modprobe.d/alsa-base.conf'
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
    run_sudo "chmod +x /usr/local/bin/graphic_card.sh" "Failed to set executable permission for graphic_card.sh."
    run_sudo "chmod +x /usr/local/bin/power_save.sh" "Failed to set executable permission for power_save.sh."

    echo "Installation completed successfully!"
else
    echo "Installation cancelled."
fi
