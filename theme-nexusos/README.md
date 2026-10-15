# Thème NexusOS

Bleu nuit, verre translucide, lueur bleue. Inspiré de la maquette de Wylan.

| Élément | Outil | Fichier |
|---|---|---|
| Fenêtres, animations, raccourcis | Hyprland | `config/hypr/hyprland.conf` |
| Îlot central + heure en haut | Waybar | `config/waybar/` |
| Menu de démarrage (Super+Espace) | rofi | `config/rofi/nexusos.rasi` |
| Dock flottant en bas | nwg-dock-hyprland | `config/nwg-dock-hyprland/style.css` |
| Terminal | kitty | `config/kitty/kitty.conf` |
| Notifications | dunst | `config/dunst/dunstrc` |
| Verrouillage (Super+Maj+L) | hyprlock | `config/hypr/hyprlock.conf` |
| Fond d'écran (original) | swaybg | `fonds/galaxie-nexus.jpg` |

## Installation (VM, en root)
```bash
cd /root/nexusos && git pull
bash theme-nexusos/install_theme_nexusos.sh
reboot
```
Les anciennes configurations sont gardées en `*.avant-theme-nexusos`.
Sur VirtualBox, les réglages de rendu logiciel sont ajoutés automatiquement (`~/.config/hypr/machine.conf`).

## Raccourcis
Super+Entrée terminal · Super+Espace menu · Super+E fichiers · Super+Q fermer · Super+F plein écran
Super+&/é/"/'… bureaux 1 à 9 · Super+G GameResume · Super+Maj+G clip ShadowRecord · Super+S SafeZone
Impr écran capture · Maj+Impr capture d'une zone · Super+Maj+L verrouiller · Super+Maj+M quitter

## Couleurs
fond `#060c22` · panneaux `rgba(6,12,34,0.8)` · bordure `#4f8bff` · accent `#2f6bff` · violet `#8b5cf6` · texte `#e6ecff`

## À venir
Icônes du bureau, logos NexusOS, couleurs automatiques depuis le fond d'écran (wallust).
