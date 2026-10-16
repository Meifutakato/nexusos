# Thème NexusOS

Bleu nuit, verre translucide, lueur bleue. Inspiré de la maquette de Wylan.

| Élément | Outil | Fichier |
|---|---|---|
| Fenêtres, animations, raccourcis | Hyprland | `config/hypr/hyprland.conf` |
| Îlot central + heure en haut | Waybar | `config/waybar/` |
| Menu de démarrage (Super+Espace) | rofi | `config/rofi/nexusos.rasi` |
| Barre du bas (menu, recherche, applications, heure) | Quickshell | `config/quickshell/Barre.qml` (applications épinglées en haut du fichier) |
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

## Barre du bas (Quickshell)

- Bouton NexusOS et champ « Rechercher » : ouvrent le menu des applications (le vrai menu Démarrer arrive à l'étape 2).
- Clic sur une application : l'ouvre, ou affiche sa fenêtre si elle est déjà ouverte (trait bleu dessous).
- Voir les erreurs : ouvrir un terminal dans la VM et taper `pkill quickshell; quickshell`.
- Revenir à l'ancien dock :
  `sed -i 's/^exec-once = quickshell$/exec-once = nwg-dock-hyprland -x -i 40 -mb 14/' ~/.config/hypr/hyprland.conf` puis redémarrer.
