# Acer Nitro 5 (AN515) Linux Fixes & Battery Optimizer

This repository provides comprehensive fixes and system-level optimizations for the Acer Nitro 5 (AN515) laptop running Linux (fully optimized for CachyOS / Arch Linux, Wayland, and the Niri compositor).

Our primary goal is to maximize battery life, configure premium audio, and resolve common hardware issues with a modular, interactive installation script.

---

## 🚀 Getting Started

The master installation script, [install.sh](file:///home/emurat/Projects/linux/acer-nitro-5-an515-linux/install.sh), is the single, modular entry point. It allows you to select exactly which optimizations you want to apply.

### 1. Make the script executable
```bash
chmod +x install.sh
```

### 2. Run the interactive installer
```bash
./install.sh
```

---

## 🛠️ Optimizations & Features

The installer offers the following modular components:

### 1. Premium Audio & Noise Cancellation
- **Echo Cancellation & Noise Suppression:** Integrates `webrtc-audio-processing` and `noise-suppression-for-voice` for crystal-clear microphone input. Automated installation uses `paru` on CachyOS (falling back to `pacman`).
- **ALSA Level Restore:** Adds a custom user-level systemd service (`alsa-restore-custom.service`) that automatically restores your customized alsamixer mic levels on boot, executing reliably after WirePlumber initializations.
- **Headset Microphone Fix:** Appends optimized kernel modules configurations to `/etc/modprobe.d/alsa-base.conf` to properly route external headset microphones.

### 2. Ultimate Battery Optimizer
Wired directly into `install.sh`, you can optionally set up the **Flutter Dev Battery Optimizer** (`install-battery-optimizer.sh`). This script configures:
- **Ryzen TDP & Undervolting Control:** Uses `ryzenadj` to dynamically adjust TDP limits and sets a global undervolt curve of `CO -20` across all cores for lower temperatures and power usage.
- **Dynamic GPU Switching:** Provides optional automated integration with `envycontrol` to lock your Nvidia GPU into `integrated` mode for maximum battery runtime, bypassing discrete GPU power draw.
- **Hardware Power Savings:** Custom systemd services dynamically manage PCIe ASPM policies, USB autosuspend, AMDGPU performance levels (`low` on battery, `auto` on AC), disk power states, and WiFi power-saving rules via `iw`.
- **Ananicy-CPP Rules:** Optimizes process priorities for development tools (Dart, Flutter, Java, VS Code, Niri) to maintain performance under resource constraints.
- **Interactive Mode Profiles:**
  - `battery-mode` (10W TDP limit, CPU EPP set to `power-saver`, restricted TDP)
  - `flutter-mode` (25W TDP limit, CPU EPP set to `performance` for compilation speed, active when BAT > 15%)
  - `ac` (35W TDP limit, CPU EPP set to `balanced` when plugged into AC power)
- **Monitoring & Status:** Provides a `battery-status` CLI tool to inspect the active profile, TDP configurations, charging state, and current battery level.
- **Sudoers Integration:** Real-user elevation enables passwordless switching between `flutter-mode`, `battery-mode`, and `battery-status`.

### 3. Standalone Nvidia Drivers Optimization
If you choose not to run Nvidia in integrated GPU mode, the installer can apply standalone driver optimizations:
- Installs power management parameters to `/etc/modprobe.d/` and custom `udev` rules to `/etc/udev/rules.d/` to optimize D3 runtime power states for discrete graphics.

---

## 📺 HDMI Fixes

If you encounter issues with external HDMI output or require full Wayland discrete GPU support, add the following parameters to your kernel command line:

```bash
rd.driver.blacklist=nouveau modprobe.blacklist=nouveau nvidia-drm.modeset=1
```

Enable the necessary Nvidia power and persistence services:
```bash
sudo systemctl enable nvidia-{suspend,resume,hibernate,persistenced}
```

---

## 🔋 Additional Power Savings

You can disable the NMI (Non-Maskable Interrupt) watchdog to save additional CPU cycles and power. Add this parameter to your kernel command line:

```bash
nmi_watchdog=0
```

---

## 🧹 Uninstallation

If you wish to remove any configurations, scripts, or systemd services created by this project, run the interactive uninstaller script:

### 1. Make the script executable
```bash
chmod +x uninstall.sh
```

### 2. Run the interactive uninstaller
```bash
./uninstall.sh
```
This script allows you to selectively uninstall audio enhancements, ALSA restores, headset mic fixes, discrete Nvidia parameters, or the entire Battery Optimizer toolchain.

