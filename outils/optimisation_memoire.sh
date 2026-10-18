#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
#  NexusOS — gestion intelligente de la mémoire (RAM)
#  En root :  bash /root/nexusos/outils/optimisation_memoire.sh
#  Annuler :  bash /root/nexusos/outils/optimisation_memoire.sh --annuler
#
#  Ce que ça fait (sans augmenter la RAM utilisée) :
#   1. zram  : une partie de la RAM devient un « swap compressé » (≈3 fois plus de place)
#              au lieu d'écrire sur le disque, beaucoup plus lent.
#   2. Réglages du noyau adaptés à zram (valeurs du wiki Arch) + protection anti-blocage.
#   3. earlyoom : si la mémoire est vraiment pleine, ferme l'application la plus gourmande
#              AVANT que tout le système gèle — jamais le bureau, la session ou SSH.
#  Tout est dans des fichiers séparés : rien d'existant n'est modifié.
# ═══════════════════════════════════════════════════════════
set -euo pipefail
if [[ $EUID -ne 0 ]]; then echo "Lance ce script en root." >&2; exit 1; fi
etape() { echo; echo "==> $*"; }

ZRAM_CONF=/etc/systemd/zram-generator.conf
SYSCTL_CONF=/etc/sysctl.d/99-nexusos-memoire.conf
TMPFILES_CONF=/etc/tmpfiles.d/nexusos-memoire.conf
EARLYOOM_CONF=/etc/default/earlyoom

etat() {
    echo "--- Mémoire ---"; free -h
    echo "--- Swap ---"; swapon --show 2>/dev/null || true
    echo "--- Les 8 programmes qui utilisent le plus de RAM ---"
    ps -eo rss,comm --sort=-rss | head -n 9 | awk 'NR==1{print "  Mo   programme"; next}{printf "%5d  %s\n", $1/1024, $2}'
}

# ── Annulation ──────────────────────────────────────────────
if [[ "${1:-}" == "--annuler" ]]; then
    etape "Annulation des réglages mémoire NexusOS"
    systemctl disable --now earlyoom.service 2>/dev/null || true
    swapoff /dev/zram0 2>/dev/null || true
    rm -f "$ZRAM_CONF" "$SYSCTL_CONF" "$TMPFILES_CONF"
    systemctl daemon-reload
    sysctl --system > /dev/null
    echo "    Fait. Redémarre pour revenir exactement à l'état d'avant."
    exit 0
fi

etape "[1/6] État AVANT"
etat

etape "[2/6] Snapshot de sécurité"
btrfs subvolume snapshot -r / "/.snapshots/avant-memoire-$(date +%F_%H%M)" || echo "    (snapshot impossible, on continue)"

etape "[3/6] Paquets (zram-generator, earlyoom)"
pacman -S --needed --noconfirm zram-generator earlyoom

etape "[4/6] zram : swap compressé en RAM"
cat > "$ZRAM_CONF" << 'EOF_ZRAM'
# NexusOS — swap compressé en mémoire (zstd). Taille maximale, pas réservée :
# la RAM n'est utilisée que si des données y sont vraiment rangées.
[zram0]
zram-size = min(ram / 2, 4096)
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF_ZRAM
systemctl daemon-reload
systemctl restart systemd-zram-setup@zram0.service || systemctl start systemd-zram-setup@zram0.service || true
echo "    Le swap sur disque existant est gardé en secours (priorité plus basse)."

etape "[5/6] Réglages du noyau"
cat > "$SYSCTL_CONF" << 'EOF_SYSCTL'
# NexusOS — mémoire (valeurs recommandées par le wiki Arch pour zram)
# Préférer le swap compressé en RAM plutôt que vider le cache des fichiers
vm.swappiness = 180
# zram : lire une page à la fois (pas de lecture anticipée inutile)
vm.page-cluster = 0
# Éviter les à-coups quand la mémoire se remplit
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
# Garder plus longtemps la liste des dossiers/fichiers en mémoire (navigation plus vive)
vm.vfs_cache_pressure = 50
# Écrire sur le disque par petits morceaux, sans geler pendant les grosses copies
vm.dirty_background_bytes = 67108864
vm.dirty_bytes = 268435456
EOF_SYSCTL
sysctl --system > /dev/null && echo "    Réglages appliqués."
# Anti-blocage du noyau (MGLRU) : protège la mémoire « en cours d'usage » pendant 1 s
cat > "$TMPFILES_CONF" << 'EOF_TMP'
# NexusOS — empêche le système de « ramer » quand la mémoire est presque pleine
w- /sys/kernel/mm/lru_gen/min_ttl_ms - - - - 1000
EOF_TMP
systemd-tmpfiles --create "$TMPFILES_CONF" 2>/dev/null || true

etape "[6/6] earlyoom : garde-fou en cas de mémoire pleine"
cat > "$EARLYOOM_CONF" << 'EOF_OOM'
# NexusOS — agit seulement si RAM libre < 5 % ET swap libre < 10 %.
# Ne ferme jamais : le bureau, la barre, la session, SSH, le système.
# Ferme en priorité : navigateurs, applications Electron, lanceurs de jeux.
EARLYOOM_ARGS="-m 5 -s 10 -r 0 --avoid (^|/)(Hyprland|quickshell|qs|sddm|sddm-helper|systemd|systemd-.*|sshd|dbus-.*|pipewire|wireplumber|swaybg|dunst|kitty)$ --prefer (^|/)(firefox|chromium|chrome|msedge|electron|Discord|discord|spotify|steamwebhelper)$"
EOF_OOM
systemctl enable --now earlyoom.service
systemctl restart earlyoom.service

echo
etape "État APRÈS"
etat
echo "--- zram ---"; zramctl 2>/dev/null || true
echo
echo "╔══════════════════════════════════════════════════════╗"
echo "  Gestion de la mémoire NexusOS activée."
echo "  Annuler : bash $0 --annuler"
echo "╚══════════════════════════════════════════════════════╝"
