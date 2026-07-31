#!/bin/bash
# ═══════════════════════════════════════════════════════
# NexusOS — Phase 1 : Installation base Arch Linux + Btrfs
# ═══════════════════════════════════════════════════════

set -e

# ════ VARIABLES — MODIFIEZ ICI AVANT DE LANCER ════════
DISK="/dev/sda"
USERNAME="wylan"
HOSTNAME="nexusos"
TIMEZONE="Europe/Paris"
LOCALE="fr_FR.UTF-8"
KEYMAP="fr"
BOOT_SIZE="512M"
SWAP_SIZE="4G"
BTRFS_OPTS="noatime,compress=zstd,space_cache=v2,discard=async"
# ══════════════════════════════════════════════════════

echo "═══════════════════════════════════════"
echo "  NexusOS — Phase 1 : Base Arch + Btrfs"
echo "═══════════════════════════════════════"

# Clavier
loadkeys $KEYMAP

# Vérifier internet
echo "[1/10] Vérification internet..."
ping -c1 archlinux.org > /dev/null || { echo "Pas d'internet !"; exit 1; }

# Synchroniser l'heure
echo "[2/10] Synchronisation heure..."
timedatectl set-ntp true

# Miroirs FR/DE
echo "[3/10] Configuration miroirs..."
reflector --country France,Germany --sort rate --save /etc/pacman.d/mirrorlist

# Partitionnement
echo "[4/10] Partitionnement de $DISK..."
sgdisk -Z $DISK
sgdisk -n 1:0:+$BOOT_SIZE -t 1:ef00 -c 1:"EFI" $DISK
sgdisk -n 2:0:+$SWAP_SIZE -t 2:8200 -c 2:"SWAP" $DISK
sgdisk -n 3:0:0 -t 3:8300 -c 3:"ROOT" $DISK

# Formater
echo "[5/10] Formatage..."
mkfs.fat -F32 ${DISK}1
mkswap ${DISK}2
mkfs.btrfs -f -L NexusOS ${DISK}3

# Créer sous-volumes Btrfs
echo "[6/10] Création sous-volumes Btrfs..."
mount ${DISK}3 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@nexusvault
btrfs subvolume create /mnt/@gameclips
btrfs subvolume create /mnt/@docbackup
umount /mnt

# Monter les sous-volumes
echo "[7/10] Montage sous-volumes..."
mount -o $BTRFS_OPTS,subvol=@ ${DISK}3 /mnt
mkdir -p /mnt/{home,.snapshots,.nexusvault,.gameclips,.docbackup,boot/efi}
mount -o $BTRFS_OPTS,subvol=@home ${DISK}3 /mnt/home
mount -o $BTRFS_OPTS,subvol=@snapshots ${DISK}3 /mnt/.snapshots
mount -o $BTRFS_OPTS,subvol=@nexusvault ${DISK}3 /mnt/.nexusvault
mount -o $BTRFS_OPTS,subvol=@gameclips ${DISK}3 /mnt/.gameclips
mount -o $BTRFS_OPTS,subvol=@docbackup ${DISK}3 /mnt/.docbackup
mount ${DISK}1 /mnt/boot/efi
swapon ${DISK}2

# Installer base Arch
echo "[8/10] Installation Arch Linux base..."
pacstrap /mnt base base-devel linux linux-firmware \
  btrfs-progs grub efibootmgr networkmanager \
  git vim sudo python python-pip

# Générer fstab
echo "[9/10] Génération fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# Copier phase 2 dans le chroot
echo "[10/10] Préparation phase 2..."
cp /root/nexusos/phase2_configure.sh /mnt/root/
chmod +x /mnt/root/phase2_configure.sh

# Passer les variables à la phase 2
cat > /mnt/root/nexusos_vars.sh << EOF
USERNAME="$USERNAME"
HOSTNAME="$HOSTNAME"
TIMEZONE="$TIMEZONE"
LOCALE="$LOCALE"
KEYMAP="$KEYMAP"
DISK="$DISK"
EOF

echo ""
echo "✓ Phase 1 terminée — Lancement phase 2..."
arch-chroot /mnt bash /root/phase2_configure.sh
