#!/usr/bin/env bash
# ============================================================
#  NexusOS — Phase 6b : nexus-veille (Rust)
#  Gèle + compresse dans zram les applis hors écran,
#  réveil instantané quand on revient dessus.
#  Usage : bash /root/nexusos/phase6b_veille.sh wylan
# ============================================================
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Lance ce script en root."; exit 1; }
USER_NAME="${1:-wylan}"
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)
[[ -n "$USER_HOME" ]] || { echo "Utilisateur $USER_NAME introuvable."; exit 1; }
SRC="$(cd "$(dirname "$0")" && pwd)/nexus-veille"
[[ -f "$SRC/Cargo.toml" ]] || { echo "Dossier $SRC introuvable (fais git pull)."; exit 1; }

log() { echo -e "\e[1;35m[NexusOS]\e[0m $*"; }

# ------------------------------------------------------------
log "1/6 Vérifications"
NOYAU=$(uname -r | cut -d. -f1-2)
if [[ "$(printf '%s\n' 5.19 "$NOYAU" | sort -V | head -n1)" != "5.19" ]]; then
  echo "Noyau $NOYAU trop ancien (5.19 minimum pour la compression)."; exit 1
fi
[[ -f /sys/fs/cgroup/cgroup.controllers ]] || { echo "cgroups v2 absents."; exit 1; }
swapon --show | grep -q zram || echo "⚠ zram inactif : lance d'abord la phase 6 (la veille gèlera sans compresser)."

# ------------------------------------------------------------
log "2/6 Rust"
pacman -S --needed --noconfirm rust

# ------------------------------------------------------------
log "3/6 Compilation (hors ligne, aucune dépendance)"
BUILD="$USER_HOME/.cache/nexus-veille-build"
rm -rf "$BUILD"
mkdir -p "$(dirname "$BUILD")"
cp -r "$SRC" "$BUILD"
chown -R "$USER_NAME:" "$USER_HOME/.cache"
sudo -u "$USER_NAME" bash -c "cd '$BUILD' && cargo test --release --offline -q && cargo build --release --offline"
install -Dm755 "$BUILD/target/release/nexus-veille" /usr/local/bin/nexus-veille
install -Dm644 "$SRC/README.md" /usr/local/share/doc/nexus-veille/README.md
rm -rf "$BUILD"

# ------------------------------------------------------------
log "4/6 Service et réglages"
install -Dm644 "$SRC/systeme/nexus-veille.service" /etc/systemd/user/nexus-veille.service

sudo -u "$USER_NAME" mkdir -p "$USER_HOME/.config/nexusos" "$USER_HOME/.config/hypr"
if [[ ! -f "$USER_HOME/.config/nexusos/veille.toml" ]]; then
  install -m644 -o "$USER_NAME" -g "$(id -gn "$USER_NAME")" "$SRC/systeme/veille.toml" "$USER_HOME/.config/nexusos/veille.toml"
else
  log "   veille.toml existant conservé"
fi
install -m644 -o "$USER_NAME" -g "$(id -gn "$USER_NAME")" "$SRC/systeme/hyprland-veille.conf" "$USER_HOME/.config/hypr/nexus-veille.conf"

# Mise à jour : si le service tourne déjà, il redémarre avec le nouveau programme
USER_UID=$(id -u "$USER_NAME")
if [[ -S "/run/user/$USER_UID/bus" ]]; then
  sudo -u "$USER_NAME" XDG_RUNTIME_DIR="/run/user/$USER_UID" systemctl --user daemon-reload || true
  sudo -u "$USER_NAME" XDG_RUNTIME_DIR="/run/user/$USER_UID" systemctl --user try-restart nexus-veille || true
  log "   service rechargé avec la nouvelle version"
fi

# ------------------------------------------------------------
log "5/6 Branchement Hyprland"
HCONF="$USER_HOME/.config/hypr/hyprland.conf"
LIGNE='source = ~/.config/hypr/nexus-veille.conf'
if [[ -f "$HCONF" ]]; then
  if ! grep -qF "$LIGNE" "$HCONF"; then
    printf '\n# NexusOS — veille compressée (phase 6b)\n%s\n' "$LIGNE" >> "$HCONF"
    log "   ajouté à la fin de hyprland.conf"
  else
    log "   déjà présent dans hyprland.conf"
  fi
else
  log "   ⚠ hyprland.conf pas encore créé (phase 5 / thème à finir)."
  log "   Après le thème, ajoute à la FIN de $HCONF :"
  log "   $LIGNE"
fi

# ------------------------------------------------------------
log "6/6 Menu Quickshell → nexus-veille"
# Même script que celui appelé par install_theme_nexusos.sh après une (ré)installation du thème
bash "$SRC/systeme/brancher-theme.sh" "$USER_NAME" || log "   ⚠ branchement du thème incomplet (voir ci-dessus)"

log "Phase 6b terminée. Au prochain lancement de Hyprland, la veille démarre toute seule."
log "Contrôle : nexus-veille statut   ·   journal : journalctl --user -u nexus-veille -f"
