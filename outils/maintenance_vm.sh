#!/usr/bin/env bash
# NexusOS — maintenance de la VM (à lancer en root, après un git pull)
#   bash /root/nexusos/outils/maintenance_vm.sh
# Fait : snapshot, miroirs fiables, mise à jour complète, fastfetch,
#        outils VirtualBox, horloge, SSH (pour piloter la VM depuis Windows).
set -euo pipefail

if [[ $EUID -ne 0 ]]; then echo "Lance ce script en root." >&2; exit 1; fi
etape() { echo; echo "==> $*"; }

etape "[1/8] Snapshot de sécurité"
NOM="/.snapshots/avant-maintenance-$(date +%F_%H%M)"
btrfs subvolume snapshot -r / "$NOM" && echo "    $NOM"

etape "[2/8] Miroirs fiables (ancienne liste gardée dans mirrorlist.ancien)"
[[ -f /etc/pacman.d/mirrorlist.ancien ]] || cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.ancien
cat > /etc/pacman.d/mirrorlist << 'EOF'
Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch
Server = https://archlinux.mirrors.ovh.net/archlinux/$repo/os/$arch
Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch
EOF

etape "[3/8] Réparation de pacman.conf (ILoveCandy) et du verrou"
sed -i '/^[[:space:]]*ILoveCandy/d' /etc/pacman.conf
sed -i '/^\[options\]/a ILoveCandy' /etc/pacman.conf
if ! pgrep -x pacman > /dev/null; then rm -f /var/lib/pacman/db.lck; fi

etape "[4/8] Horloge synchronisée automatiquement"
timedatectl set-ntp true || true

etape "[5/8] Mise à jour complète du système (peut être long)"
pacman -Syy --needed --noconfirm archlinux-keyring
pacman -Su --noconfirm

etape "[6/8] fastfetch, SSH et outils VirtualBox"
pacman -S --needed --noconfirm fastfetch openssh virtualbox-guest-utils
systemctl enable --now vboxservice.service || echo "    (vboxservice : à vérifier après redémarrage)"
systemctl enable --now sshd.service

etape "[7/8] Clavier français (terminal et écran de connexion)"
echo "KEYMAP=fr" > /etc/vconsole.conf
localectl set-x11-keymap fr || true

etape "[8/8] Vérification"
fastfetch || true
IP=$(ip -4 -o addr show scope global | awk '{print $4}' | cut -d/ -f1 | head -n1)
echo
echo "╔══════════════════════════════════════════════════════╗"
echo "  Maintenance terminée."
echo "  Adresse IP de la VM : ${IP:-inconnue}"
echo
echo "  Depuis Windows (Invite de commandes) :"
echo "      ssh wylan@${IP:-ADRESSE_IP}"
echo "  mot de passe : celui de wylan, puis 'su -' pour root."
echo "  Le copier-coller fonctionne dans cette fenêtre."
echo "╚══════════════════════════════════════════════════════╝"
echo "Pense à redémarrer (reboot) : le noyau a peut-être été mis à jour."
