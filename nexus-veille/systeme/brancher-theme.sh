#!/usr/bin/env bash
# ============================================================
#  NexusOS — branche le thème Quickshell sur nexus-veille
#  Les applis lancées depuis le bureau (menu, barre du bas,
#  recommandés, espace IA…) passent par « nexus-veille lance »
#  et peuvent donc être mises en veille.
#
#  Appelé par : phase6b_veille.sh  ET  install_theme_nexusos.sh
#  (après une réinstallation du thème, la veille est rebranchée).
#  Rejouable sans risque : ce qui est déjà branché n'est pas retouché.
#  Usage (root) : bash brancher-theme.sh wylan
# ============================================================
set -uo pipefail

[[ $EUID -eq 0 ]] || { echo "Lance ce script en root."; exit 1; }
USER_NAME="${1:-wylan}"
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)
SRC="$(cd "$(dirname "$0")/.." && pwd)"
log() { echo -e "\e[1;35m[NexusOS]\e[0m $*"; }

QS="$USER_HOME/.config/quickshell"
ETAT="$QS/Etat.qml"
PAGE="$QS/PageApplications.qml"

if ! command -v nexus-veille >/dev/null; then
  log "   nexus-veille non installé : thème laissé tel quel"
  exit 0
fi
if [[ ! -f "$ETAT" ]] || ! grep -q 'function lancer(commande)' "$ETAT"; then
  log "   ⚠ Etat.qml du thème introuvable ou différent : rien modifié"
  exit 0
fi

# --- 1. Fonction executer() dans Etat.qml (menu) -------------------------
if grep -q 'function executer(appli)' "$ETAT"; then
  log "   menu déjà branché"
else
  # Copies de secours (restaurer : cp Etat.qml.avant-veille Etat.qml)
  sudo -u "$USER_NAME" cp "$ETAT" "$ETAT.avant-veille"
  [[ -f "$PAGE" ]] && sudo -u "$USER_NAME" cp "$PAGE" "$PAGE.avant-veille"

  # Le fragment est dans /root : copié dans /tmp pour que l'utilisateur puisse le lire
  FRAGMENT=$(mktemp /tmp/nexus-executer.XXXX.qml)
  install -m644 "$SRC/systeme/quickshell-executer.qml" "$FRAGMENT"

  # Modifications faites en tant qu'utilisateur (les fichiers restent à lui)
  sudo -u "$USER_NAME" sed -i "/function lancer(commande)/r $FRAGMENT" "$ETAT"
  sudo -u "$USER_NAME" sed -i 's/^\(\s*\)appli\.execute();/\1executer(appli);/' "$ETAT"
  rm -f "$FRAGMENT"

  if grep -q 'function executer(appli)' "$ETAT" && grep -q 'executer(appli);' "$ETAT"; then
    log "   menu branché"
  else
    log "   ⚠ modification incomplète : retour aux fichiers d'origine"
    sudo -u "$USER_NAME" cp "$ETAT.avant-veille" "$ETAT"
    [[ -f "$PAGE.avant-veille" ]] && sudo -u "$USER_NAME" cp "$PAGE.avant-veille" "$PAGE"
    exit 1
  fi
fi

# --- 2. Toutes les icônes / listes qui lancent une appli -----------------
# (barre du bas, liste du menu, recherche…). Les jeux (PageJeux.qml) restent
# tels quels : ils ne sont jamais mis en veille.
while IFS= read -r -d '' F; do
  [[ "$F" == "$ETAT" || "$(basename "$F")" == "PageJeux.qml" ]] && continue
  if grep -qE '[A-Za-z_][A-Za-z0-9_.]*\.execute\(\)' "$F"; then
    # Le fichier n'est pas encore branché : c'est sa version d'origine → copie de secours
    sudo -u "$USER_NAME" cp "$F" "$F.avant-veille"
    sudo -u "$USER_NAME" sed -i 's/\([A-Za-z_][A-Za-z0-9_.]*\)\.execute()/Etat.executer(\1)/g' "$F"
    log "   branché : ${F#"$QS"/}"
  fi
done < <(find "$QS" -name '*.qml' -print0)

# --- 3. Etat.lancer([...]) : recommandés, espace IA, xdg-open… -----------
ANCIEN='function lancer(commande) { Quickshell.execDetached(commande); }'
NOUVEAU='function lancer(commande) { Quickshell.execDetached(["nexus-veille", "lance"].concat(commande)); }'
if grep -qF "$NOUVEAU" "$ETAT"; then
  log "   Etat.lancer déjà branché"
elif grep -qF "$ANCIEN" "$ETAT"; then
  sudo -u "$USER_NAME" cp "$ETAT" "$ETAT.avant-lancer"
  sudo -u "$USER_NAME" sed -i "s|$ANCIEN|$NOUVEAU|" "$ETAT"
  if grep -qF "$NOUVEAU" "$ETAT"; then
    log "   Etat.lancer branché (recommandés, espace IA…)"
  else
    log "   ⚠ Etat.lancer non modifié : retour au fichier d'origine"
    sudo -u "$USER_NAME" cp "$ETAT.avant-lancer" "$ETAT"
  fi
else
  log "   ⚠ Etat.lancer a une forme inattendue : non modifié"
fi

exit 0
