# NexusOS

Distribution Linux gaming + bureautique basée sur Arch Linux.

## Installation

```bash
# Dans le live Arch Linux (VirtualBox ou machine réelle)
git clone https://github.com/VotreUsername/nexusos.git
cd nexusos
chmod +x *.sh theme/*.sh

# Éditer les variables (DISK, USERNAME, etc.)
vim phase1_install_base.sh

# Lancer (phases 2→5 automatiques)
sudo bash phase1_install_base.sh
```

## Fonctionnalités

- **ShadowRecord** — Buffer circulaire 5 min, clips automatiques
- **GameResume** — Notes de session par jeu
- **ActionReplay** — Reconstruction de documents perdus
- **SafeZone** — 20 versions par fichier + SHA256
- **NetSwitch** — Sélection auto meilleure connexion
- **Thème HyperOS** — Hyprland + Waybar glassmorphism

## Stack

- Arch Linux rolling + Btrfs 6 sous-volumes
- Hyprland Wayland + Waybar + Rofi + Dunst + Kitty
- Steam + Proton GE + GameMode + MangoHud
- TCP BBR + Drivers Xiaomi mt76

## RAM idle : ~167 Mo
