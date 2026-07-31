#!/bin/bash
# ═══════════════════════════════════════════════════════
# NexusOS — Phase 2 : Configuration système + GRUB + paru
# ═══════════════════════════════════════════════════════

set -e
source /root/nexusos_vars.sh

echo "═══════════════════════════════════════"
echo "  NexusOS — Phase 2 : Configuration"
echo "═══════════════════════════════════════"

# Timezone
echo "[1/8] Timezone..."
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Locale
echo "[2/8] Locale..."
echo "$LOCALE UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

# Hostname
echo "[3/8] Hostname..."
echo "$HOSTNAME" > /etc/hostname
cat > /etc/hosts << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF

# Pacman optimisé
echo "[4/8] Configuration pacman..."
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 10/' /etc/pacman.conf
sed -i 's/#Color/Color/' /etc/pacman.conf
sed -i 's/#VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf
echo "ILoveCandy" >> /etc/pacman.conf

# GRUB low-latency gaming
echo "[5/8] GRUB gaming..."
cat > /etc/default/grub << 'EOF'
GRUB_DEFAULT=0
GRUB_TIMEOUT=3
GRUB_DISTRIBUTOR="NexusOS"
GRUB_CMDLINE_LINUX_DEFAULT="quiet loglevel=3 nowatchdog mitigations=off transparent_hugepage=madvise preempt=full threadirqs skew_tick=1 tsc=reliable clocksource=tsc"
GRUB_CMDLINE_LINUX=""
GRUB_PRELOAD_MODULES="part_gpt part_msdos"
GRUB_TERMINAL_INPUT=console
EOF

# mkinitcpio
sed -i 's/^MODULES=.*/MODULES=(btrfs)/' /etc/mkinitcpio.conf
sed -i 's/^COMPRESSION=.*/COMPRESSION="zstd"/' /etc/mkinitcpio.conf
mkinitcpio -P
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=NexusOS
grub-mkconfig -o /boot/grub/grub.cfg

# Utilisateur
echo "[6/8] Création utilisateur $USERNAME..."
useradd -m -G wheel,audio,video,storage,optical -s /bin/bash $USERNAME
echo "$USERNAME:nexusos" | chpasswd
echo "root:nexusos" | chpasswd
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers

# Services
echo "[7/8] Services..."
systemctl enable NetworkManager
systemctl enable fstrim.timer

# paru AUR
echo "[8/8] Installation paru..."
cd /tmp
git clone https://aur.archlinux.org/paru.git
chown -R $USERNAME:$USERNAME paru
cd paru
sudo -u $USERNAME makepkg -si --noconfirm
cd /root

echo ""
echo "✓ Phase 2 terminée — Lancement phase 3..."
bash /root/phase3_gaming.sh
