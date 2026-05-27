#!/bin/bash
#═══════════════════════════════════════════════════════════════════
# Acer Nitro 5 (AN515) Linux Fixes & Battery Optimizer Uninstaller
#═══════════════════════════════════════════════════════════════════

echo "===================================================="
echo "  Acer Nitro 5 Linux Fixes & Optimizer Uninstaller  "
echo "===================================================="

# 1. Uninstallation of Premium Audio & Noise Suppression
read -p "Do you want to uninstall echo cancelling and noise suppression configs? (y/n) " -r
if [[ $REPLY =~ ^[yY]$ ]]; then
    echo "Removing echo cancel config..."
    rm -f "$HOME/.config/pipewire/pipewire.conf.d/99-input-echo-cancel.conf"

    echo "Restarting pipewire..."
    systemctl --user restart wireplumber pipewire pipewire-pulse >/dev/null 2>&1

    # Ask if they want to uninstall the packages too
    read -p "Do you want to uninstall webrtc-audio-processing and noise-suppression-for-voice? (y/n) " -r
    if [[ $REPLY =~ ^[yY]$ ]]; then
        if command -v paru &>/dev/null; then
            paru -R --noconfirm webrtc-audio-processing noise-suppression-for-voice || true
        else
            sudo pacman -R --noconfirm webrtc-audio-processing noise-suppression-for-voice || true
        fi
    fi
    echo "Echo cancel uninstalled successfully!"
fi

# 2. Uninstallation of ALSA custom restore service
read -p "Do you want to remove the custom alsamixer mic restore settings? (y/n) " -r
if [[ $REPLY =~ ^[yY]$ ]]; then
    echo "Disabling systemd user service..."
    systemctl --user disable alsa-restore-custom.service >/dev/null 2>&1 || true
    
    echo "Removing systemd user service and state files..."
    rm -f "$HOME/.config/systemd/user/alsa-restore-custom.service"
    rm -f "$HOME/.config/asound.state"
    
    systemctl --user daemon-reload
    echo "Mic restore settings uninstalled successfully!"
fi

# 3. Headset Mic Fix Uninstallation
read -p "Do you want to remove the headset-mic fix (alsa-base.conf addition)? (y/n) " -r
if [[ $REPLY =~ ^[yY]$ ]]; then
    if [[ -f /etc/modprobe.d/alsa-base.conf ]]; then
        echo "Removing options snd-hda-intel from /etc/modprobe.d/alsa-base.conf..."
        sudo sed -i '/options snd-hda-intel model=auto,dell-headset-multi/d' /etc/modprobe.d/alsa-base.conf
        echo "Headset mic configuration removed successfully!"
    else
        echo "alsa-base.conf file not found."
    fi
fi

# 4. Nvidia Fixes Uninstallation
read -p "Do you want to remove discrete Nvidia fixes (udev rules & modprobe configs)? (y/n) " -r
if [[ $REPLY =~ ^[yY]$ ]]; then
    echo "Removing Nvidia optimization files..."
    sudo rm -f /etc/modprobe.d/nvidia-power-management.conf
    sudo rm -f /etc/modprobe.d/nvidia-uvm.conf
    sudo rm -f /etc/udev/rules.d/80-nvidia-pm.rules
    
    sudo udevadm control --reload-rules
    echo "Discrete Nvidia fixes uninstalled successfully!"
fi

# 5. Battery Optimizer Uninstallation
read -p "Do you want to completely uninstall the Battery Optimizer? (y/n) " -r
if [[ $REPLY =~ ^[yY]$ ]]; then
    echo "Stopping and disabling battery optimizer services..."
    for svc in battery-optimizer-resume.service hw-power-battery.service hw-power-ac.service ryzenadj-battery.service ryzenadj-ac.service; do
        if systemctl is-active "$svc" &>/dev/null; then
            echo "  → Stopping $svc..."
            sudo systemctl stop "$svc" || true
        fi
        if systemctl is-enabled "$svc" &>/dev/null; then
            echo "  → Disabling $svc..."
            sudo systemctl disable "$svc" || true
        fi
    done

    echo "Removing systemd service files..."
    sudo rm -f /etc/systemd/system/hw-power-battery.service
    sudo rm -f /etc/systemd/system/hw-power-ac.service
    sudo rm -f /etc/systemd/system/ryzenadj-battery.service
    sudo rm -f /etc/systemd/system/ryzenadj-ac.service
    sudo rm -f /etc/systemd/system/battery-optimizer-resume.service
    sudo systemctl daemon-reload

    echo "Removing local scripts..."
    sudo rm -f /usr/local/bin/hw-power-battery
    sudo rm -f /usr/local/bin/hw-power-ac
    sudo rm -f /usr/local/bin/battery-optimizer-resume
    sudo rm -f /usr/local/bin/flutter-mode
    sudo rm -f /usr/local/bin/battery-mode
    sudo rm -f /usr/local/bin/battery-status

    echo "Removing udev rule targets..."
    sudo rm -f /etc/udev/rules.d/99-powertargets.rules
    sudo udevadm control --reload-rules

    echo "Removing ananicy-cpp rules..."
    sudo rm -f /etc/ananicy.d/99-flutter-dev.rules
    sudo systemctl restart ananicy-cpp >/dev/null 2>&1 || true

    echo "Removing sudoers integration..."
    sudo rm -f /etc/sudoers.d/battery-optimizer

    echo "Cleaning state and logs..."
    sudo rm -rf /var/lib/battery-optimizer
    sudo rm -f /var/log/battery-optimizer.log

    # Reset GPU mode to default hybrid mode if they set it to integrated
    if command -v envycontrol &>/dev/null; then
        CURRENT_GPU=$(envycontrol --query 2>/dev/null || echo "hybrid")
        if [[ "$CURRENT_GPU" == "integrated" ]]; then
            read -p "Nvidia GPU is currently set to integrated mode. Switch back to hybrid mode? (y/n) " -r
            if [[ $REPLY =~ ^[yY]$ ]]; then
                echo "Switching GPU to hybrid..."
                sudo envycontrol -s hybrid
            fi
        fi
    fi

    # Reset powerprofilesctl to default balanced
    if command -v powerprofilesctl &>/dev/null; then
        powerprofilesctl set balanced || true
    fi

    # Ask if they want to remove envycontrol and ryzenadj package dependencies
    read -p "Do you want to uninstall ryzenadj and envycontrol? (y/n) " -r
    if [[ $REPLY =~ ^[yY]$ ]]; then
        if command -v paru &>/dev/null; then
            paru -R --noconfirm ryzenadj envycontrol || true
        else
            sudo pacman -R --noconfirm ryzenadj envycontrol || true
        fi
    fi

    echo "Battery Optimizer completely uninstalled!"
fi

echo "===================================================="
echo "              Uninstallation Completed              "
echo "===================================================="
