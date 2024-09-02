# Acer Nitro 5 (AN515) Linux Fixes

This project is dedicated to providing fixes and optimizations for the Acer Nitro 5 (AN515) laptop running Linux. It addresses various issues related to audio, microphone settings, CPU performance, HDMI functionality, and power-saving. Additionally, this guide assumes you are using the "noise-suppression-for-voice" Git project for audio noise suppression and the "auto-cpufreq" project for CPU optimization.

## Audio - Wifi Fixes and Power Management

To improve audio quality and enable power saving for wifi on your Acer Nitro 5 (AN515) laptop running Linux, follow these steps:

1. **Give necessary permissions to script**:
    ```bash
   chmod +x install.sh
   ```

2. **Run script**: Run script and answer prompts to add fixes you need.
   ```bash
   ./install.sh
   ```

## HDMI Fixes

If you encounter any issues related to HDMI connectivity on your laptop, copy the folder from "HDMI-Fixes" to the root directory (`/`) and add the following to your kernel command line:

   ```bash
   rd.driver.blacklist=nouveau modprobe.blacklist=nouveau nvidia-drm.modeset=1
   ```

You also need to start a few services to make sure everything works fine (This also enables wayland support for nvidia):

   ```bash
   sudo systemctl enable nvidia-{suspend,resume,hibernate,persistenced}
   ```

## Touchpad Gestures

For Touchpad gestures to work under X11, you can use a project called Fusuma. First, install the required dependencies for Fusuma and then install Fusuma itself. You can find Fusuma [here](https://github.com/iberianpig/fusuma).

My config file for KDE desktop is located in the "Touchpad-Fixes" directory. Simply copy the contents to your `$HOME` directory. To use my config file you have to install "xdotool" and two other fusuma plugins:

- [fusuma-plugin-wmctrl](https://github.com/iberianpig/fusuma-plugin-wmctrl)
- [fusuma-plugin-keypress](https://github.com/iberianpig/fusuma-plugin-keypress)


## Power Saving

To save additional power on your laptop, you can apply the following settings:

1. NMI (Non-Maskable Interrupt) watchdog is a feature that periodically checks the system's responsiveness. Disabling it can help save power. To disable add this to kernel command line:

   ```bash
   nmi_watchdog=0
   ```

Please note that this project is meant to provide guidance and solutions for common issues faced by Acer Nitro 5 (AN515) laptop users running Linux. It's important to back up your data and exercise caution when making system changes.

Feel free to contribute to this project by submitting pull requests with additional fixes or improvements to benefit the Acer Nitro 5 (AN515) Linux community.

## TODO
- Make the script cover all specific fixes in this repository
- Add an uninstaller script
