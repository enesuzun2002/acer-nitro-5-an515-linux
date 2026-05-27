#!/bin/bash
#═══════════════════════════════════════════════════════════════════
# Acer Nitro 5 (Ryzen 7 4800H + GTX 1650)
# Flutter Dev Battery Optimizer — v7.9 (Ultimate/Bugfix Release)
#
# Distro     : CachyOS / Arch Linux
# Compositor : Niri (Wayland)
# Bootloader : Limine
# GPU        : CPPC aktif, amd-pstate driver
#
# Undervolt (Curve Optimizer All Cores):
# Formül: 1048576 - 20 = 1048556
#═══════════════════════════════════════════════════════════════════

set -euo pipefail

USE_INTEGRATED=0
if [[ "${1:-}" == "--integrated" ]]; then
    USE_INTEGRATED=1
fi

if [[ $EUID -ne 0 ]]; then
    echo "Root gerekli: sudo bash $(basename "$0")"
    exit 1
fi

STATE_DIR="/var/lib/battery-optimizer"
STATE_FILE="$STATE_DIR/current_mode"
LOG_FILE="/var/log/battery-optimizer.log"
mkdir -p "$STATE_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

write_file() {
    [[ -f "$1" ]] && log "  → Güncelleniyor: $1" || log "  → Oluşturuluyor: $1"
}

die() {
    log "FATAL: $1"
    exit 1
}

REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo '')}"
[[ -z "$REAL_USER" ]] && log "UYARI: Kullanıcı tespit edilemedi."

log "════════════════════════════════════════"
log "KURULUM BAŞLADI — v7.9 (Nihai Sürüm)"
log "════════════════════════════════════════"

#═══════════════════════════════════════════════════════════════════
# 1. CACHYOS ÖN KONTROLLER
#═══════════════════════════════════════════════════════════════════
log "=== 1. CachyOS Ön Kontroller ==="

CURRENT_KERNEL=$(uname -r)
if echo "$CURRENT_KERNEL" | grep -q "cachyos"; then
    log "  BİLGİ: linux-cachyos çekirdeği tespit edildi."
fi

command -v paru &>/dev/null || die "'paru' bulunamadı: sudo pacman -S paru"

CPUFREQ_DRIVER=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver 2>/dev/null || echo "bilinmiyor")
log "  Mevcut CPU driver: $CPUFREQ_DRIVER"

#═══════════════════════════════════════════════════════════════════
# 2. BAĞIMLILIKLAR
#═══════════════════════════════════════════════════════════════════
log "=== 2. Bağımlılıklar ==="

if pacman -Q tlp &>/dev/null; then
    log "  → TLP kurulu, kaldırılıyor..."
    pacman -R --noconfirm tlp >> "$LOG_FILE" 2>&1 || log "  ✗ TLP kaldırılamadı."
fi

if ! systemctl is-active power-profiles-daemon &>/dev/null; then
    log "  → power-profiles-daemon etkinleştiriliyor..."
    systemctl unmask power-profiles-daemon 2>/dev/null || true
    pacman -S --needed --noconfirm power-profiles-daemon >> "$LOG_FILE" 2>&1
    systemctl enable --now power-profiles-daemon >> "$LOG_FILE" 2>&1
fi

log "  → hdparm ve iw kuruluyor..."
pacman -S --needed --noconfirm hdparm iw >> "$LOG_FILE" 2>&1

[[ -n "$REAL_USER" ]] || die "REAL_USER yok, AUR kurulamaz."
for pkg in envycontrol ryzenadj; do
    if ! sudo -u "$REAL_USER" paru -Q "$pkg" &>/dev/null; then
        log "  → $pkg kuruluyor..."
        sudo -u "$REAL_USER" paru -S --needed --noconfirm --noprogressbar "$pkg" || die "$pkg kurulamadı."
    fi
done

#═══════════════════════════════════════════════════════════════════
# 3. NVIDIA dGPU
#═══════════════════════════════════════════════════════════════════
if [[ "$USE_INTEGRATED" == "1" ]]; then
    log "=== 3. NVIDIA dGPU ==="
    CURRENT_GPU=$(envycontrol --query 2>/dev/null || echo "unknown")
    if [[ "$CURRENT_GPU" != "integrated" ]]; then
        log "  → envycontrol: integrated moda geçiliyor..."
        envycontrol -s integrated || die "envycontrol başarısız."
    else
        log "  ✓ GPU zaten integrated modda."
    fi
else
    log "=== 3. NVIDIA dGPU (Atlandı) ==="
fi

#═══════════════════════════════════════════════════════════════════
# 4. HW-POWER SERVİSİ
#═══════════════════════════════════════════════════════════════════
log "=== 4. hw-power servisi ==="

write_file "/usr/local/bin/hw-power-battery"
cat << 'EOF' > /usr/local/bin/hw-power-battery
#!/bin/bash
LOG=/var/log/battery-optimizer.log
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [hw-power] Pil modu donanım ayarları uygulanıyor..." >> "$LOG"

if [[ -w /sys/module/pcie_aspm/parameters/policy ]]; then
    echo powersupersave > /sys/module/pcie_aspm/parameters/policy 2>/dev/null || true
fi

for card in /sys/class/drm/card*/device/power_dpm_force_performance_level; do
    echo "low" > "$card" 2>/dev/null || true
done

for dev in /sys/bus/pci/devices/*/power/control; do
    echo auto > "$dev" 2>/dev/null || true
done

for iface in /sys/class/net/wl*; do
    iw dev "$(basename "$iface")" set power_save on 2>/dev/null || true
done

for dev in /sys/bus/usb/devices/*/power/autosuspend_delay_ms; do
    echo 2000 > "$dev" 2>/dev/null || true
done
for dev in /sys/bus/usb/devices/*/power/control; do
    echo auto > "$dev" 2>/dev/null || true
done

for disk in /dev/sd?; do
    [[ -b "$disk" ]] || continue
    hdparm -B 128 "$disk" >> "$LOG" 2>&1 || true
done
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [hw-power] Pil donanım tasarrufu devrede." >> "$LOG"
EOF
chmod +x /usr/local/bin/hw-power-battery

write_file "/usr/local/bin/hw-power-ac"
cat << 'EOF' > /usr/local/bin/hw-power-ac
#!/bin/bash
LOG=/var/log/battery-optimizer.log
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [hw-power] AC modu donanım ayarları uygulanıyor..." >> "$LOG"

if [[ -w /sys/module/pcie_aspm/parameters/policy ]]; then
    echo default > /sys/module/pcie_aspm/parameters/policy 2>/dev/null || true
fi

for card in /sys/class/drm/card*/device/power_dpm_force_performance_level; do
    echo "auto" > "$card" 2>/dev/null || true
done

for dev in /sys/bus/pci/devices/*/power/control; do
    echo on > "$dev" 2>/dev/null || true
done

for iface in /sys/class/net/wl*; do
    iw dev "$(basename "$iface")" set power_save off 2>/dev/null || true
done

for disk in /dev/sd?; do
    [[ -b "$disk" ]] || continue
    hdparm -B 254 "$disk" >> "$LOG" 2>&1 || true
done
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [hw-power] AC tam performans devrede." >> "$LOG"
EOF
chmod +x /usr/local/bin/hw-power-ac

write_file "/etc/systemd/system/hw-power-battery.service"
cat << 'EOF' > /etc/systemd/system/hw-power-battery.service
[Unit]
Description=Hardware power settings — Battery

[Service]
Type=oneshot
ExecStart=/usr/local/bin/hw-power-battery
EOF

write_file "/etc/systemd/system/hw-power-ac.service"
cat << 'EOF' > /etc/systemd/system/hw-power-ac.service
[Unit]
Description=Hardware power settings — AC

[Service]
Type=oneshot
ExecStart=/usr/local/bin/hw-power-ac
EOF

#═══════════════════════════════════════════════════════════════════
# 5. ANANICY-CPP 
#═══════════════════════════════════════════════════════════════════
log "=== 5. ananicy-cpp Kuralları ==="
mkdir -p /etc/ananicy.d/

write_file "/etc/ananicy.d/99-flutter-dev.rules"
cat << 'EOF' > /etc/ananicy.d/99-flutter-dev.rules
name=niri nice=-5 sched=rr ioclass=realtime
name=dart nice=10 sched=batch ioclass=best-effort
name=flutter nice=10 sched=batch ioclass=best-effort
name=java nice=15 sched=batch ioclass=best-effort
name=code nice=5 sched=normal ioclass=best-effort
EOF
systemctl restart ananicy-cpp >> "$LOG_FILE" 2>&1 || log "  ✗ ananicy-cpp yeniden başlatılamadı."

#═══════════════════════════════════════════════════════════════════
# 6. RYZENADJ SERVİSLERİ (TDP + UNDERVOLT + PPD ENTEGRASYONU)
#═══════════════════════════════════════════════════════════════════
log "=== 6. ryzenadj servisleri ==="
write_file "/etc/systemd/system/ryzenadj-battery.service"
cat << 'EOF' > /etc/systemd/system/ryzenadj-battery.service
[Unit]
Description=Ryzen TDP & Undervolt & PPD — Battery (10W + CO -20)

[Service]
Type=oneshot
ExecStart=/usr/bin/ryzenadj --stapm-limit=7000 --fast-limit=10000 --slow-limit=8000 --tctl-temp=75 --set-coall=1048556
ExecStartPost=-/usr/bin/powerprofilesctl set power-saver
ExecStartPost=/usr/bin/bash -c 'echo battery > /var/lib/battery-optimizer/current_mode'
EOF

write_file "/etc/systemd/system/ryzenadj-ac.service"
cat << 'EOF' > /etc/systemd/system/ryzenadj-ac.service
[Unit]
Description=Ryzen TDP & Undervolt & PPD — AC (35W + CO -20)

[Service]
Type=oneshot
ExecStart=/usr/bin/ryzenadj --stapm-limit=35000 --fast-limit=35000 --slow-limit=35000 --tctl-temp=85 --set-coall=1048556
ExecStartPost=-/usr/bin/powerprofilesctl set balanced
ExecStartPost=/usr/bin/bash -c 'echo ac > /var/lib/battery-optimizer/current_mode'
EOF

#═══════════════════════════════════════════════════════════════════
# 7. UDEV — AC/Battery Geçiş Tetikleyici (Bugfix: Restart kullanıldı)
#═══════════════════════════════════════════════════════════════════
log "=== 7. Udev Kuralları ==="
write_file "/etc/udev/rules.d/99-powertargets.rules"
cat << 'EOF' > /etc/udev/rules.d/99-powertargets.rules
SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="/usr/bin/systemctl --no-block restart ryzenadj-battery.service hw-power-battery.service"
SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", RUN+="/usr/bin/systemctl --no-block restart ryzenadj-ac.service hw-power-ac.service"
EOF

#═══════════════════════════════════════════════════════════════════
# 8. SUSPEND/RESUME HOOK (Bugfix: Uyanınca donanım kısıtlaması tekrar eklendi)
#═══════════════════════════════════════════════════════════════════
log "=== 8. Suspend/Resume Hook ==="
write_file "/usr/local/bin/battery-optimizer-resume"
cat << 'RESUME_EOF' > /usr/local/bin/battery-optimizer-resume
#!/bin/bash
STATE_FILE="/var/lib/battery-optimizer/current_mode"
LOG="/var/log/battery-optimizer.log"
MODE=$(cat "$STATE_FILE" 2>/dev/null || echo "battery")

echo "[$(date '+%Y-%m-%d %H:%M:%S')] [resume] Uyanma, $MODE modu (CO -20 ile) uygulanıyor..." >> "$LOG"

case "$MODE" in
    flutter)
        /usr/local/bin/flutter-mode --quiet
        /usr/local/bin/hw-power-battery
        ;;
    battery)
        /usr/local/bin/battery-mode --quiet
        /usr/local/bin/hw-power-battery
        ;;
    ac)
        ryzenadj --stapm-limit=35000 --fast-limit=35000 --slow-limit=35000 --tctl-temp=85 --set-coall=1048556 >> "$LOG" 2>&1 || true
        powerprofilesctl set balanced >> "$LOG" 2>&1 || true
        /usr/local/bin/hw-power-ac
        ;;
esac
RESUME_EOF
chmod +x /usr/local/bin/battery-optimizer-resume

write_file "/etc/systemd/system/battery-optimizer-resume.service"
cat << 'EOF' > /etc/systemd/system/battery-optimizer-resume.service
[Unit]
Description=Re-apply battery optimizer after resume
After=suspend.target hibernate.target hybrid-sleep.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/battery-optimizer-resume

[Install]
WantedBy=suspend.target hibernate.target hybrid-sleep.target
EOF
systemctl enable battery-optimizer-resume.service >> "$LOG_FILE" 2>&1

#═══════════════════════════════════════════════════════════════════
# 9. FLUTTER-MODE SCRIPT
#═══════════════════════════════════════════════════════════════════
log "=== 9. Flutter Mode Betiği ==="
write_file "/usr/local/bin/flutter-mode"
cat << 'FLUTTER_EOF' > /usr/local/bin/flutter-mode
#!/bin/bash
set -euo pipefail

STATE_FILE="/var/lib/battery-optimizer/current_mode"
LOG="/var/log/battery-optimizer.log"
QUIET="${1:-}"

log() {
    [[ "$QUIET" != "--quiet" ]] && echo "$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [flutter-mode] $1" >> "$LOG"
}

[[ $EUID -ne 0 ]] && { echo "Sudo gerekli: sudo flutter-mode"; exit 1; }

AC=$(grep -q 1 /sys/class/power_supply/*/online 2>/dev/null && echo "1" || echo "0")
if [[ "$AC" == "1" ]]; then
    log "AC bağlı — geçiş iptal edildi."
    exit 0
fi

BAT=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1 || echo "100")
if [[ "$BAT" -lt 15 ]]; then
    log "HATA: Batarya %$BAT (Min %15 gerekli)."
    exit 1
fi

CURRENT=$(cat "$STATE_FILE" 2>/dev/null || echo "battery")
if [[ "$CURRENT" == "flutter" ]]; then exit 0; fi

log "flutter-mode (25W TDP, CO -20, performance EPP) aktifleştiriliyor..."
ryzenadj --stapm-limit=20000 --fast-limit=25000 --slow-limit=20000 --tctl-temp=85 --set-coall=1048556 >> "$LOG" 2>&1 || exit 1
powerprofilesctl set performance >> "$LOG" 2>&1 || true

cat << 'EOF' > /etc/ananicy.d/99-flutter-dev.rules
name=niri nice=-5 sched=rr ioclass=realtime
name=dart nice=0 sched=normal ioclass=best-effort
name=flutter nice=0 sched=normal ioclass=best-effort
name=java nice=5 sched=normal ioclass=best-effort
name=code nice=0 sched=normal ioclass=best-effort
EOF
systemctl restart ananicy-cpp >> "$LOG" 2>&1 || true

echo "flutter" > "$STATE_FILE"
log "flutter-mode AKTİF."
FLUTTER_EOF
chmod +x /usr/local/bin/flutter-mode

#═══════════════════════════════════════════════════════════════════
# 10. BATTERY-MODE SCRIPT
#═══════════════════════════════════════════════════════════════════
log "=== 10. Battery Mode Betiği ==="
write_file "/usr/local/bin/battery-mode"
cat << 'BATTERY_EOF' > /usr/local/bin/battery-mode
#!/bin/bash
set -euo pipefail

STATE_FILE="/var/lib/battery-optimizer/current_mode"
LOG="/var/log/battery-optimizer.log"
QUIET="${1:-}"

log() {
    [[ "$QUIET" != "--quiet" ]] && echo "$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [battery-mode] $1" >> "$LOG"
}

[[ $EUID -ne 0 ]] && exit 1
CURRENT=$(cat "$STATE_FILE" 2>/dev/null || echo "battery")
if [[ "$CURRENT" == "battery" ]]; then exit 0; fi

log "battery-mode (10W TDP, CO -20, power-saver EPP) aktifleştiriliyor..."
ryzenadj --stapm-limit=7000 --fast-limit=10000 --slow-limit=8000 --tctl-temp=75 --set-coall=1048556 >> "$LOG" 2>&1 || true
powerprofilesctl set power-saver >> "$LOG" 2>&1 || true

cat << 'EOF' > /etc/ananicy.d/99-flutter-dev.rules
name=niri nice=-5 sched=rr ioclass=realtime
name=dart nice=10 sched=batch ioclass=best-effort
name=flutter nice=10 sched=batch ioclass=best-effort
name=java nice=15 sched=batch ioclass=best-effort
name=code nice=5 sched=normal ioclass=best-effort
EOF
systemctl restart ananicy-cpp >> "$LOG" 2>&1 || true

echo "battery" > "$STATE_FILE"
log "battery-mode AKTİF."
BATTERY_EOF
chmod +x /usr/local/bin/battery-mode

#═══════════════════════════════════════════════════════════════════
# 11. STATUS SCRIPT
#═══════════════════════════════════════════════════════════════════
log "=== 11. Status Betiği ==="
write_file "/usr/local/bin/battery-status"
cat << 'STATUS_EOF' > /usr/local/bin/battery-status
#!/bin/bash
STATE_FILE="/var/lib/battery-optimizer"
MODE=$(cat "$STATE_FILE/current_mode" 2>/dev/null || echo "?")
BAT=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1 || echo "?")
AC=$(grep -q 1 /sys/class/power_supply/*/online 2>/dev/null && echo "1" || echo "0")
PPD_PROFILE=$(powerprofilesctl get 2>/dev/null || echo "?")
AMD_GPU_DPM=$(cat /sys/class/drm/card*/device/power_dpm_force_performance_level 2>/dev/null | head -n 1 || echo "?")

echo "══════════════════════════════════════════════"
echo " Mod          : $MODE"
echo " PPD profili  : $PPD_PROFILE"
echo " AMD GPU Güç  : $AMD_GPU_DPM"
echo " Undervolt    : Aktif (CO -20 / 1048556)"
echo " Batarya      : %$BAT"
echo " AC           : $([ "$AC" = "1" ] && echo 'Bağlı (35W Sınırı)' || echo 'Bağlı değil')"
echo " Log Dosyası  : /var/log/battery-optimizer.log"
echo "══════════════════════════════════════════════"
STATUS_EOF
chmod +x /usr/local/bin/battery-status

#═══════════════════════════════════════════════════════════════════
# 12. SUDOERS
#═══════════════════════════════════════════════════════════════════
log "=== 12. Sudoers ==="
if [[ -n "$REAL_USER" ]]; then
    echo "$REAL_USER ALL=(root) NOPASSWD: /usr/local/bin/flutter-mode, /usr/local/bin/battery-mode, /usr/local/bin/battery-status" \
        > /etc/sudoers.d/battery-optimizer
    chmod 440 /etc/sudoers.d/battery-optimizer
fi

#═══════════════════════════════════════════════════════════════════
# 13. SERVİSLER ETKİNLEŞTİR VE UYGULA
#═══════════════════════════════════════════════════════════════════
log "=== 13. Servisler Başlatılıyor ==="
systemctl daemon-reload >> "$LOG_FILE" 2>&1
udevadm control --reload-rules >> "$LOG_FILE" 2>&1

AC_NOW=$(grep -q 1 /sys/class/power_supply/*/online 2>/dev/null && echo "1" || echo "0")
if [[ "$AC_NOW" == "1" ]]; then
    systemctl restart ryzenadj-ac.service hw-power-ac.service >> "$LOG_FILE" 2>&1
    log "  ✓ Başlangıç: AC modu algılandı ve uygulandı."
else
    systemctl restart ryzenadj-battery.service hw-power-battery.service >> "$LOG_FILE" 2>&1
    log "  ✓ Başlangıç: Battery modu algılandı ve uygulandı."
fi

echo "════════════════════════════════════════════════════════"
echo " KURULUM TAMAMLANDI — v7.9 (Hatasız Nihai Sürüm)"
echo "════════════════════════════════════════════════════════"