#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
#  NexusOS — Module IA (séparé du thème)
#  Assistant (Super+A), IA locales, IA en ligne, agents IA.
#
#  En root :  bash /root/nexusos/ia-nexusos/install_ia_nexusos.sh
#  Retirer :  bash /root/nexusos/ia-nexusos/install_ia_nexusos.sh --desinstaller
#             (tes IA, agents et créations dans ~/IA sont gardés)
#
#  Nécessite le thème NexusOS (theme-nexusos) déjà installé.
#  Ollama n'est pas installé ici : bouton « Installer » dans Paramètres › IA locales.
# ═══════════════════════════════════════════════════════════
set -euo pipefail

if [[ $EUID -ne 0 ]]; then echo "Lance ce script en root." >&2; exit 1; fi

ICI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACTION=installer
USERNAME=""
for a in "$@"; do
    case "$a" in
        --desinstaller) ACTION=desinstaller ;;
        *) USERNAME="$a" ;;
    esac
done
if [[ -z "$USERNAME" && -f /root/nexusos_vars.sh ]]; then
    # shellcheck disable=SC1091
    source /root/nexusos_vars.sh
fi
USERNAME="${USERNAME:-wylan}"
if ! id "$USERNAME" &>/dev/null; then echo "Utilisateur '$USERNAME' introuvable." >&2; exit 1; fi
MAISON="$(getent passwd "$USERNAME" | cut -d: -f6)"
CONF="$MAISON/.config"
QS="$CONF/quickshell"

etape() { echo; echo "==> $*"; }

# Anciens fichiers IA posés dans le thème par la livraison du 17 oct. (avant la séparation)
nettoyer_ancien() {
    rm -f "$QS"/Assistant.qml "$QS"/PageAssistant.qml "$QS"/PageIaLocales.qml \
          "$QS"/PageIaEnLigne.qml "$QS"/PageAgents.qml "$QS"/icones/assistant.svg
}

if [[ "$ACTION" == desinstaller ]]; then
    etape "Retrait du module IA"
    rm -rf "$QS/ia"
    nettoyer_ancien
    echo "# Module IA non installé (voir ia-nexusos)" > "$CONF/hypr/ia.conf"
    chown "$USERNAME:$USERNAME" "$CONF/hypr/ia.conf"
    rm -f /usr/local/bin/nexus-ia /usr/share/pixmaps/nexusos-assistant.svg \
          "$MAISON/.local/share/applications/nexusos-assistant.desktop"
    echo "    Module retiré. Tes données restent dans $MAISON/IA"
    echo "    (clés API : $CONF/nexusos/ia-cles.json — à supprimer toi-même si tu veux)."
    echo "    Reconnecte-toi (ou reboot) pour mettre à jour le bureau."
    exit 0
fi

if [[ ! -f "$QS/Etat.qml" ]]; then
    echo "Le thème NexusOS n'est pas installé : lance d'abord theme-nexusos/install_theme_nexusos.sh" >&2
    exit 1
fi
if ! grep -q "iaInstalle" "$QS/Etat.qml"; then
    echo "Ton thème est trop ancien pour le module IA : réinstalle d'abord theme-nexusos (git pull)." >&2
    exit 1
fi

etape "[1/4] Snapshot de sécurité"
btrfs subvolume snapshot -r / "/.snapshots/avant-ia-nexusos-$(date +%F_%H%M)" || echo "    (snapshot impossible, on continue)"

etape "[2/4] Moteur nexus-ia"
pacman -S --needed --noconfirm python >/dev/null
install -m755 "$ICI/nexus-ia" /usr/local/bin/nexus-ia
echo "    /usr/local/bin/nexus-ia"

etape "[3/4] Fenêtres et pages des Paramètres"
nettoyer_ancien
rm -rf "$QS/ia"
install -d "$QS/ia"
install -m644 "$ICI"/quickshell/ia/* "$QS/ia/"
install -m644 "$ICI/hypr/ia.conf" "$CONF/hypr/ia.conf"
install -Dm644 "$ICI/assistant.svg" /usr/share/pixmaps/nexusos-assistant.svg
install -d "$MAISON/.local/share/applications"
cat > "$MAISON/.local/share/applications/nexusos-assistant.desktop" << 'EOF_DESK'
[Desktop Entry]
Type=Application
Name=Assistant IA
GenericName=Assistant NexusOS
Comment=Discussion, CV et maquettes avec ton IA locale ou en ligne
Exec=quickshell ipc call assistant ouvrir
Icon=/usr/share/pixmaps/nexusos-assistant.svg
Categories=Utility;
Keywords=ia;ai;assistant;cv;maquette;chat;
EOF_DESK

etape "[4/4] Dossiers séparés dans ~/IA"
for d in IA IA/Locales IA/En-ligne IA/Agents IA/Créations IA/Assistant; do
    install -d -o "$USERNAME" -g "$USERNAME" -m 755 "$MAISON/$d"
    echo "    ~/$d"
done
chown -R "$USERNAME:$USERNAME" "$QS/ia" "$CONF/hypr/ia.conf" "$MAISON/.local/share/applications/nexusos-assistant.desktop"

echo
echo "╔══════════════════════════════════════════════════════╗"
echo "  Module IA installé."
echo "  Reboot (ou reconnexion), puis :"
echo "    Super+I › Intelligence artificielle : ajouter une IA"
echo "    Super+A : assistant"
echo "  Pour le retirer : bash $ICI/install_ia_nexusos.sh --desinstaller"
echo "╚══════════════════════════════════════════════════════╝"
