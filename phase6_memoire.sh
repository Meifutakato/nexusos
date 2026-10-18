#!/usr/bin/env bash
# ============================================================
#  NexusOS — Phase 6 : Mémoire
#  zram + swap de secours Btrfs + réglages noyau + anti-gel (OOM)
#  + snapshots système automatiques (snapper / grub-btrfs)
#  Usage : bash /root/nexusos/phase6_memoire.sh wylan
# ============================================================
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Lance ce script en root."; exit 1; }
USER_NAME="${1:-wylan}"

log() { echo -e "\e[1;35m[NexusOS]\e[0m $*"; }

# ------------------------------------------------------------
log "Installation des paquets"
pacman -S --needed --noconfirm zram-generator earlyoom snapper snap-pac grub-btrfs inotify-tools

# ------------------------------------------------------------
# 1. zram : swap compressé en RAM (zstd), prioritaire
# ------------------------------------------------------------
log "1/6 zram"
cat > /etc/systemd/zram-generator.conf <<'EOF'
[zram0]
zram-size = min(ram, 8192)
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF
systemctl daemon-reload
systemctl restart systemd-zram-setup@zram0.service

# zswap doit être désactivé quand on utilise zram
echo 0 > /sys/module/zswap/parameters/enabled 2>/dev/null || true
if ! grep -q 'zswap.enabled=0' /etc/default/grub; then
  sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 zswap.enabled=0"/' /etc/default/grub
fi

# ------------------------------------------------------------
# 2. Swap de secours sur disque (sous-volume Btrfs dédié, hors snapshots)
# ------------------------------------------------------------
log "2/6 Swapfile de secours 4 Go"
if [[ ! -f /swap/swapfile ]]; then
  btrfs subvolume create /swap
  btrfs filesystem mkswapfile --size 4g --uuid clear /swap/swapfile
fi
grep -q '/swap/swapfile' /etc/fstab || echo '/swap/swapfile none swap defaults,pri=10 0 0' >> /etc/fstab
swapon -p 10 /swap/swapfile 2>/dev/null || true

# ------------------------------------------------------------
# 3. Réglages noyau (optimisés zram + réactivité)
# ------------------------------------------------------------
log "3/6 Réglages sysctl"
cat > /etc/sysctl.d/99-nexus-memoire.conf <<'EOF'
# zram : on peut swapper agressivement, c'est de la RAM compressée
vm.swappiness = 180
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.page-cluster = 0
# garder le cache des fichiers/dossiers plus longtemps
vm.vfs_cache_pressure = 50
# écritures disque par petits paquets -> pas de micro-gels pendant les copies
vm.dirty_bytes = 268435456
vm.dirty_background_bytes = 67108864
EOF
sysctl --system >/dev/null

# ------------------------------------------------------------
# 4. Anti-gel : earlyoom tue le bon processus avant que tout freeze
#    Protège le bureau et les outils NexusOS, sacrifie d'abord les navigateurs
# ------------------------------------------------------------
log "4/6 earlyoom"
cat > /etc/default/earlyoom <<'EOF'
EARLYOOM_ARGS="-r 0 -m 4 -s 10 --avoid ^(Hyprland|Xwayland|sddm|kitty|waybar|nexus-.*) --prefer ^(firefox|chromium|electron)"
EOF
systemctl enable --now earlyoom.service

# ------------------------------------------------------------
# 5. Snapshots système automatiques (snapper sur @ -> @snapshots)
# ------------------------------------------------------------
log "5/6 Snapper + grub-btrfs"
if [[ ! -f /etc/snapper/configs/root ]]; then
  umount /.snapshots
  rm -rf /.snapshots
  snapper --no-dbus -c root create-config /
  btrfs subvolume delete /.snapshots     # sous-volume créé par snapper, on garde le nôtre (@snapshots)
  mkdir /.snapshots
  mount -a
  chmod 750 /.snapshots
fi

# Limites adaptées à un disque de 40 Go
snapper -c root set-config \
  "TIMELINE_CREATE=yes" \
  "TIMELINE_LIMIT_HOURLY=3" \
  "TIMELINE_LIMIT_DAILY=5" \
  "TIMELINE_LIMIT_WEEKLY=2" \
  "TIMELINE_LIMIT_MONTHLY=0" \
  "TIMELINE_LIMIT_YEARLY=0" \
  "NUMBER_LIMIT=10" \
  "NUMBER_LIMIT_IMPORTANT=5" \
  "ALLOW_USERS=${USER_NAME}"
chown :"${USER_NAME}" /.snapshots

systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
systemctl enable --now grub-btrfsd.service    # snapshots bootables depuis GRUB

# Clips gaming : pas de copy-on-write pour les grosses vidéos (moins de fragmentation)
[[ -d /.gameclips ]] && chattr +C /.gameclips 2>/dev/null || true

# ------------------------------------------------------------
# 6. Commande de contrôle : nexus-memoire
# ------------------------------------------------------------
log "6/6 Commande nexus-memoire"
cat > /usr/local/bin/nexus-memoire <<'EOF'
#!/usr/bin/env bash
echo -e "\e[1;35m== RAM ==\e[0m";       free -h
echo -e "\e[1;35m== Swap ==\e[0m";      swapon --show
echo -e "\e[1;35m== zram ==\e[0m";      zramctl
echo -e "\e[1;35m== earlyoom ==\e[0m";  systemctl is-active earlyoom
echo -e "\e[1;35m== Derniers snapshots ==\e[0m"; snapper -c root list 2>/dev/null | tail -n 5
EOF
chmod +x /usr/local/bin/nexus-memoire

# ------------------------------------------------------------
grub-mkconfig -o /boot/grub/grub.cfg
snapper -c root create -c number -d "Phase 6 mémoire — état propre"

log "Phase 6 terminée. Redémarre (reboot), puis lance : nexus-memoire"
