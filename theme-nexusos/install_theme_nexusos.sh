#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
#  NexusOS — Installation du thème NexusOS
#  En root :  bash /root/nexusos/theme-nexusos/install_theme_nexusos.sh
#  (utilisateur par défaut : celui de /root/nexusos_vars.sh, sinon wylan)
# ═══════════════════════════════════════════════════════════
set -euo pipefail

if [[ $EUID -ne 0 ]]; then echo "Lance ce script en root." >&2; exit 1; fi

ICI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USERNAME="${1:-}"
if [[ -z "$USERNAME" && -f /root/nexusos_vars.sh ]]; then
    # shellcheck disable=SC1091
    source /root/nexusos_vars.sh
fi
USERNAME="${USERNAME:-wylan}"
if ! id "$USERNAME" &>/dev/null; then echo "Utilisateur '$USERNAME' introuvable." >&2; exit 1; fi
MAISON="$(getent passwd "$USERNAME" | cut -d: -f6)"
CONF="$MAISON/.config"

etape() { echo; echo "==> $*"; }

etape "[1/7] Snapshot de sécurité"
btrfs subvolume snapshot -r / "/.snapshots/avant-theme-nexusos-$(date +%F_%H%M)" || echo "    (snapshot impossible, on continue)"

etape "[2/7] Paquets du thème"
# Essentiels : sans eux, le bureau ne s'affiche pas correctement
pacman -S --needed --noconfirm waybar rofi kitty dunst hyprlock swaybg \
    grim slurp wl-clipboard ttf-jetbrains-mono-nerd noto-fonts papirus-icon-theme
# Optionnels : un échec ne bloque pas
ECHECS=()
for p in pavucontrol thunar; do
    pacman -S --needed --noconfirm "$p" || ECHECS+=("$p")
done
# Quickshell : dessine la barre du bas (dépôts officiels, sinon AUR via paru)
pacman -S --needed --noconfirm quickshell \
    || sudo -u "$USERNAME" paru -S --needed --noconfirm quickshell \
    || ECHECS+=("quickshell")

etape "[3/7] Fond d'écran"
install -Dm644 "$ICI/fonds/galaxie-nexus.jpg" /usr/share/backgrounds/nexusos/galaxie-nexus.jpg

etape "[4/7] Configuration (anciens fichiers sauvegardés en .avant-theme-nexusos)"
cd "$ICI/config"
find . -type f | while read -r f; do
    cible="$CONF/${f#./}"
    if [[ -f "$cible" && ! -f "$cible.avant-theme-nexusos" ]]; then
        cp "$cible" "$cible.avant-theme-nexusos"
    fi
    install -Dm644 "$f" "$cible"
    echo "    ${cible/#$MAISON/\~}"
done

# Hyprland 0.5x lit hyprland.lua en priorité s'il existe : on le met de côté
if [[ -f "$CONF/hypr/hyprland.lua" ]]; then
    mv "$CONF/hypr/hyprland.lua" "$CONF/hypr/hyprland.lua.avant-theme-nexusos"
    echo "    hyprland.lua mis de côté (sinon il remplacerait hyprland.conf)"
fi

etape "[5/7] Réglages propres à cette machine"
MACHINE="$CONF/hypr/machine.conf"
{
    echo "# Généré par install_theme_nexusos.sh — réglages de cette machine"
    echo "env = LANG,fr_FR.UTF-8"
    if [[ "$(systemd-detect-virt 2>/dev/null || true)" == "oracle" ]]; then
        echo "# VirtualBox détecté : rendu logiciel (sinon écran noir)"
        echo "env = WLR_RENDERER_ALLOW_SOFTWARE,1"
        echo "env = LIBGL_ALWAYS_SOFTWARE,1"
        echo "env = WLR_NO_HARDWARE_CURSORS,1"
        echo "cursor {"
        echo "    no_hardware_cursors = true"
        echo "}"
        echo "exec-once = VBoxClient --clipboard"
        echo "    VirtualBox détecté : réglages ajoutés" >&2
    fi
} > "$MACHINE"

# Les applications épinglées se règlent dans ~/.config/quickshell/Barre.qml
mkdir -p "$MAISON/.cache"

etape "[6/7] Droits des fichiers"
chown -R "$USERNAME:$USERNAME" "$CONF" "$MAISON/.cache"

etape "[7/7] Écran de connexion"
systemctl enable sddm.service

echo
echo "╔══════════════════════════════════════════════════════╗"
echo "  Thème NexusOS installé."
if (( ${#ECHECS[@]} > 0 )); then
echo "  ⚠ Non installés (à réessayer plus tard) : ${ECHECS[*]}"
fi
echo
echo "  Pour l'essayer : reboot, puis connexion avec $USERNAME"
echo "  (session Hyprland, clavier français)."
echo
echo "  Super+Entrée : terminal    Super+Espace : menu"
echo "  Super+E : fichiers         Super+Q : fermer"
echo "  Super+Maj+L : verrouiller  Super+Maj+M : quitter"
echo "╚══════════════════════════════════════════════════════╝"
