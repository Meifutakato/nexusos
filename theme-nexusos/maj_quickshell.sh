#!/usr/bin/env bash
# ============================================================
#  NexusOS — met à jour l'interface Quickshell (bureau + Paramètres)
#  sans réinstaller tout le thème.
#  Copie theme-nexusos/config/quickshell/ vers ~/.config/quickshell/,
#  garde une sauvegarde, puis rebranche la veille compressée.
#  Usage (root) : bash /root/nexusos/theme-nexusos/maj_quickshell.sh wylan
# ============================================================
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Lance ce script en root."; exit 1; }
USER_NAME="${1:-wylan}"
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)
[[ -n "$USER_HOME" ]] || { echo "Utilisateur $USER_NAME introuvable."; exit 1; }
GROUPE=$(id -gn "$USER_NAME")
ICI="$(cd "$(dirname "$0")" && pwd)"
SRC="$ICI/config/quickshell"
DEST="$USER_HOME/.config/quickshell"
SAUVE="$USER_HOME/.config/quickshell.avant-maj"

log() { echo -e "\e[1;35m[NexusOS]\e[0m $*"; }

[[ -d "$SRC" ]] || { echo "Sources introuvables : $SRC (fais git pull)."; exit 1; }
[[ -d "$DEST" ]] || { echo "Quickshell n'est pas installé pour $USER_NAME : lance d'abord install_theme_nexusos.sh."; exit 1; }

log "1/3 Sauvegarde de l'interface actuelle → ~/.config/quickshell.avant-maj"
rm -rf "$SAUVE"
cp -a "$DEST" "$SAUVE"

log "2/3 Copie des nouveaux fichiers"
# Ajoute et remplace, ne supprime rien (le dossier ia/ du module IA est conservé)
cp -r "$SRC"/. "$DEST"/
chown -R "$USER_NAME:$GROUPE" "$DEST" "$SAUVE"
chmod -R u+rwX "$DEST" "$SAUVE"   # l'utilisateur doit pouvoir écrire dans sa propre interface
chmod +x "$DEST"/*.sh "$DEST"/*.py 2>/dev/null || true

log "3/3 Veille compressée"
BRANCHER="$ICI/../nexus-veille/systeme/brancher-theme.sh"
if command -v nexus-veille >/dev/null && [[ -f "$BRANCHER" ]]; then
  bash "$BRANCHER" "$USER_NAME" || log "   ⚠ branchement de la veille incomplet (voir ci-dessus)"
else
  log "   veille non installée : rien à brancher"
fi

log "Interface à jour. Quickshell se recharge tout seul."
log "Retour en arrière : rm -rf ~/.config/quickshell && mv ~/.config/quickshell.avant-maj ~/.config/quickshell"
