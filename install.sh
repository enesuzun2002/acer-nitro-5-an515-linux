#!/bin/bash

# Check if the user wants to proceed
read -p "Do you want enable echo cancelling and noise suppression for voice? (y/n) " -r
if [[ $REPLY =~ ^[yY]$ ]]; then
    echo "Installing required packages for echo cancelling and noise suppression..."
    if command -v paru &>/dev/null; then
        paru -Sy --needed --noconfirm webrtc-audio-processing noise-suppression-for-voice
    else
        sudo pacman -Sy --needed --noconfirm webrtc-audio-processing noise-suppression-for-voice
    fi

    if [ $? -ne 0 ]; then
        echo "Error: Failed to install required packages! Please verify your package manager database sync."
        exit 1
    fi

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

read -p "Do you want to configure and save custom alsamixer values for mic restore on boot? (y/n) " -r
if [[ $REPLY =~ ^[yY]$ ]]; then
    echo "Opening alsamixer..."
    echo "Instructions: Adjust your microphone levels, capture settings, and mute states. Press ESC to save and close."
    sleep 2
    alsamixer

    echo "Saving your custom soundcard state..."
    mkdir -p $HOME/.config/
    alsactl --file $HOME/.config/asound.state store
    
    if [ $? -ne 0 ]; then
        echo "Error saving custom ALSA state!"
        exit 1
    else
        echo "Creating systemd user service for reliable ALSA restore..."
        mkdir -p $HOME/.config/systemd/user/
        cat << 'EOF' > $HOME/.config/systemd/user/alsa-restore-custom.service
[Unit]
Description=Restore custom ALSA state for mic
After=wireplumber.service pipewire.service

[Service]
Type=oneshot
ExecStart=-/usr/bin/alsactl -F --file %h/.config/asound.state restore
RemainAfterExit=yes

[Install]
WantedBy=default.target
EOF
        systemctl --user daemon-reload
        
        # Enable and start the service, capturing stderr and stdout for debugging
        SYSTEMD_OUTPUT=$(systemctl --user enable --now alsa-restore-custom.service 2>&1)
        if [ $? -ne 0 ]; then
            echo "Error setting up systemd service!"
            echo "Debugging Details: $SYSTEMD_OUTPUT"
            exit 1
        else
            echo "Installation completed successfully!"
        fi
    fi
else
    echo "Custom ALSA restore configuration cancelled."
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

read -p "Do you want to install the new battery optimizer (install-battery-optimizer.sh)? (y/n) " -r
if [[ $REPLY =~ ^[yY]$ ]]; then
    read -p "Do you want to set Nvidia to integrated mode via envycontrol for maximum battery savings? (y/n) " -r
    if [[ $REPLY =~ ^[yY]$ ]]; then
        echo "Running battery optimizer with Nvidia set to integrated..."
        sudo bash ./install-battery-optimizer.sh --integrated
    else
        echo "Running battery optimizer without touching Nvidia..."
        sudo bash ./install-battery-optimizer.sh
        
        read -p "Do you want to apply Nvidia fixes (power management rules, optimus desktop, etc.) since you are not using integrated mode? (y/n) " -r
        if [[ $REPLY =~ ^[yY]$ ]]; then
             echo "Applying Nvidia fixes..."
             sudo cp -r ./Nvidia/Driver-Parameters/etc/modprobe.d/* /etc/modprobe.d/ 2>/dev/null || true
             sudo cp -r ./Nvidia/Driver-Parameters/etc/udev/rules.d/* /etc/udev/rules.d/ 2>/dev/null || true
             echo "Nvidia fixes applied successfully!"
        fi
    fi
else
    echo "Battery optimizer installation skipped."
fi
