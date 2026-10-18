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
for p in pavucontrol thunar xdg-user-dirs xdg-utils libnotify gvfs qt6-svg fastfetch \
         python hyprpolkitagent libpulse bluez-utils network-manager-applet; do
    pacman -S --needed --noconfirm "$p" || ECHECS+=("$p")
done
# Quickshell : dessine la barre du bas (dépôts officiels, sinon AUR via paru)
pacman -S --needed --noconfirm quickshell \
    || sudo -u "$USERNAME" paru -S --needed --noconfirm quickshell \
    || ECHECS+=("quickshell")

# Lecteur NexusOS : moteur mpv + interface uosc (AUR). paru ne redemande pas le mot de passe :
# autorisation temporaire de pacman pour l'utilisateur, retirée à la fin du script.
pacman -S --needed --noconfirm mpv || ECHECS+=("mpv")
echo "$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/pacman" > /etc/sudoers.d/90-nexusos-installation
chmod 440 /etc/sudoers.d/90-nexusos-installation
trap 'rm -f /etc/sudoers.d/90-nexusos-installation' EXIT
sudo -u "$USERNAME" paru -S --needed --noconfirm mpv-uosc || ECHECS+=("mpv-uosc")

# Outils de jeu : ActionReplay (gpu-screen-recorder) et reprise du dernier jeu
for p in gpu-screen-recorder wf-recorder ffmpeg; do      # wf-recorder : mode de secours sans vraie carte graphique
    pacman -S --needed --noconfirm "$p" || ECHECS+=("$p")
done
# L'ancien ShadowRecord (ffmpeg/X11, ne marchait pas sous Wayland) est remplacé
pkill -f "python3 /usr/local/bin/nexus-shadowrecord" 2>/dev/null || true
rm -f /etc/systemd/user/nexus-shadowrecord.service /etc/systemd/user/default.target.wants/nexus-shadowrecord.service \
      "$MAISON/.config/systemd/user/default.target.wants/nexus-shadowrecord.service"
install -m755 "$ICI"/outils-jeux/nexus-shadowrecord "$ICI"/outils-jeux/nexus-clip-sauve "$ICI"/outils-jeux/nexus-reprise /usr/local/bin/
if [[ -d /.gameclips ]]; then
    install -d -o "$USERNAME" -g "$USERNAME" -m 755 /.gameclips/clips
fi

etape "[3/7] Fond d'écran et logo NexusOS"
install -Dm644 "$ICI/fonds/galaxie-nexus.jpg" /usr/share/backgrounds/nexusos/galaxie-nexus.jpg
install -Dm644 "$ICI/logos/nexusos.svg" /usr/share/pixmaps/nexusos.svg
install -Dm644 "$ICI/logos/nexusos.svg" /usr/share/icons/hicolor/scalable/apps/nexusos.svg

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
        echo "# Résolution de l'écran de la VM (VirtualBox ne l'ajuste pas tout seul sous Wayland)."
        echo "# Autres choix possibles : 1600x900, 1366x768, 2560x1440"
        echo "monitor = , 1920x1080@60, auto, 1"
        echo "    VirtualBox détecté : réglages ajoutés" >&2
    fi
} > "$MACHINE"

# Réglage d'écran choisi dans Paramètres (créé vide la première fois, jamais écrasé)
[[ -f "$CONF/hypr/ecran.conf" ]] || echo "# Réglé par Paramètres › Écran" > "$CONF/hypr/ecran.conf"
# Emplacement du module IA (rempli par ia-nexusos/install_ia_nexusos.sh, jamais écrasé ici)
[[ -f "$CONF/hypr/ia.conf" ]] || echo "# Module IA non installé (voir ia-nexusos)" > "$CONF/hypr/ia.conf"

# Lecteur NexusOS : entrée de menu et lecteur par défaut des vidéos et de la musique
install -Dm644 "$ICI/config/quickshell/icones/lecteur.svg" /usr/share/pixmaps/nexusos-lecteur.svg
install -d "$MAISON/.local/share/applications"
cat > "$MAISON/.local/share/applications/nexusos-lecteur.desktop" << 'EOF_LECTEUR'
[Desktop Entry]
Type=Application
Name=Lecteur NexusOS
GenericName=Lecteur vidéo et musique
Comment=Lire les vidéos, les clips de jeu et la musique
Exec=mpv --player-operation-mode=pseudo-gui -- %U
Icon=/usr/share/pixmaps/nexusos-lecteur.svg
Categories=AudioVideo;Video;Audio;Player;
MimeType=video/mp4;video/x-matroska;video/webm;video/quicktime;video/x-msvideo;video/mpeg;video/ogg;audio/mpeg;audio/flac;audio/ogg;audio/x-wav;audio/mp4;
Keywords=vidéo;film;musique;clip;lecteur;
EOF_LECTEUR
sudo -u "$USERNAME" xdg-mime default nexusos-lecteur.desktop \
    video/mp4 video/x-matroska video/webm video/quicktime video/x-msvideo video/mpeg \
    audio/mpeg audio/flac audio/ogg audio/x-wav audio/mp4 2>/dev/null || true

# Paramètres NexusOS visibles dans le menu et la recherche
install -Dm644 "$ICI/config/quickshell/icones/parametres.svg" /usr/share/pixmaps/nexusos-parametres.svg
install -d "$MAISON/.local/share/applications"
cat > "$MAISON/.local/share/applications/nexusos-parametres.desktop" << 'EOF_DESK'
[Desktop Entry]
Type=Application
Name=Paramètres
GenericName=Paramètres NexusOS
Comment=Réseau, Bluetooth, son, écran, applications, mises à jour
Exec=quickshell ipc call parametres ouvrir
Icon=/usr/share/pixmaps/nexusos-parametres.svg
Categories=Settings;System;
Keywords=réglages;configuration;wifi;bluetooth;son;écran;
EOF_DESK

# Effets allégés (en option) : dans VirtualBox, tout le dessin passe par le processeur.
# Pour les activer :  NEXUS_ALLEGER=1 bash install_theme_nexusos.sh
ALLEGEMENT="$CONF/hypr/allegement.conf"
if [[ "${NEXUS_ALLEGER:-0}" == "1" && "$(systemd-detect-virt 2>/dev/null || true)" == "oracle" ]]; then
    cat > "$ALLEGEMENT" << 'EOF_ALLEGE'
# Généré par install_theme_nexusos.sh — VirtualBox : effets allégés pour la fluidité
# (sur un vrai PC avec carte graphique, ce fichier reste vide)
decoration {
    blur {
        size = 5
        passes = 1
        xray = true
    }
    shadow {
        enabled = false
    }
}
animations {
    bezier = rapide, 0.25, 1, 0.5, 1
    animation = windows, 1, 3, rapide
    animation = fade, 1, 3, rapide
    animation = workspaces, 1, 3, rapide
}
misc {
    vfr = true
}
EOF_ALLEGE
    echo "    VirtualBox : effets allégés (flou léger, sans ombres, animations courtes)"
else
    echo "# Généré par install_theme_nexusos.sh — effets complets (NEXUS_ALLEGER=1 pour les alléger)" > "$ALLEGEMENT"
fi

# Les applications épinglées se règlent dans ~/.config/quickshell/Barre.qml
mkdir -p "$MAISON/.cache"

# Dossiers personnels en français (Documents, Images, Musique, Vidéos, Téléchargements)
sudo -u "$USERNAME" env LANG=fr_FR.UTF-8 xdg-user-dirs-update --force 2>/dev/null || true

etape "[6/7] Droits des fichiers"
chown -R "$USERNAME:$USERNAME" "$CONF" "$MAISON/.cache" "$MAISON/.local"

etape "[7/7] Écran de connexion NexusOS"
rm -rf /usr/share/sddm/themes/nexusos
install -d /usr/share/sddm/themes/nexusos
install -m644 "$ICI"/sddm/nexusos/* /usr/share/sddm/themes/nexusos/
install -d /etc/sddm.conf.d
cat > /etc/sddm.conf.d/10-nexusos.conf << 'EOF_SDDM'
# Écran de connexion NexusOS — pour revenir à l'ancien : supprimer ce fichier
[Theme]
Current=nexusos
EOF_SDDM
# Clavier français sur l'écran de connexion
localectl set-x11-keymap fr 2>/dev/null || true
systemctl enable sddm.service

# NexusOS — rebrancher la veille compressée si elle est installée
BRANCHER="$(cd "$(dirname "$0")/.." && pwd)/nexus-veille/systeme/brancher-theme.sh"
if command -v nexus-veille >/dev/null && [[ -f "$BRANCHER" ]]; then
  bash "$BRANCHER" "$USERNAME" || ECHECS+=("veille")
fi

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
echo "  Super+I : Paramètres"
echo "╚══════════════════════════════════════════════════════╝"
