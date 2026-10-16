#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
#  NexusOS — Phase 6 : applications du quotidien et du jeu
#  En root :  bash /root/nexusos/phase6_applications.sh
#  Non bloquant : si un paquet échoue, le script continue et le signale à la fin.
# ═══════════════════════════════════════════════════════════
set -uo pipefail
if [[ $EUID -ne 0 ]]; then echo "Lance ce script en root." >&2; exit 1; fi

USERNAME="${1:-}"
if [[ -z "$USERNAME" && -f /root/nexusos_vars.sh ]]; then
    # shellcheck disable=SC1091
    source /root/nexusos_vars.sh
fi
USERNAME="${USERNAME:-wylan}"
etape() { echo; echo "==> $*"; }
ECHECS=()

installer() {        # dépôts officiels
    for p in "$@"; do
        pacman -S --needed --noconfirm "$p" > /dev/null 2>&1 && echo "    ✓ $p" || { echo "    ✗ $p"; ECHECS+=("$p"); }
    done
}
installer_aur() {    # AUR, via paru en tant qu'utilisateur
    for p in "$@"; do
        sudo -u "$USERNAME" paru -S --needed --noconfirm "$p" > /dev/null 2>&1 && echo "    ✓ $p (AUR)" || { echo "    ✗ $p (AUR)"; ECHECS+=("$p"); }
    done
}

etape "[1/7] Snapshot de sécurité"
btrfs subvolume snapshot -r / "/.snapshots/avant-phase6-$(date +%F_%H%M)" || echo "    (snapshot impossible, on continue)"

etape "[2/7] Mise à jour des listes de paquets"
pacman -Sy --noconfirm > /dev/null && echo "    ✓ listes à jour"

etape "[3/7] Internet"
installer firefox firefox-i18n-fr

etape "[4/7] Bureautique et outils"
installer libreoffice-fresh libreoffice-fresh-fr \
          mousepad gnome-calculator file-roller thunar-archive-plugin

etape "[5/7] Photos, vidéos, musique"
installer loupe vlc vlc-plugins-all     # depuis le découpage du paquet, VLC a besoin de ses greffons
installer_aur spotify

etape "[6/7] Jeux et discussion"
installer discord gamemode lib32-gamemode
installer_aur heroic-games-launcher-bin
usermod -aG gamemode "$USERNAME" 2>/dev/null || true

etape "[7/7] Création 3D (optionnel, ~400 Mo)"
read -r -t 20 -p "    Installer Blender ? [o/N] (20 s) " REPONSE || REPONSE=""
if [[ "${REPONSE,,}" == o* ]]; then installer blender; else echo "    Blender ignoré (relance le script plus tard si besoin)"; fi

echo
echo "╔══════════════════════════════════════════════════════╗"
echo "  Phase 6 terminée."
if (( ${#ECHECS[@]} > 0 )); then
echo "  ⚠ Non installés (à réessayer) : ${ECHECS[*]}"
fi
echo "  Les nouvelles applications apparaissent dans le menu,"
echo "  et celles qui sont épinglées dans la barre du bas."
echo "  Réglages : Super+I › Applications."
echo "╚══════════════════════════════════════════════════════╝"
