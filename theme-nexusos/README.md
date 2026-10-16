# Thème NexusOS

Bleu nuit, verre translucide, lueur bleue. Inspiré de la maquette de Wylan.

| Élément | Outil | Fichier |
|---|---|---|
| Fenêtres, animations, raccourcis | Hyprland | `config/hypr/hyprland.conf` |
| Barre du haut : bureaux, îlot, heure | Quickshell | `config/quickshell/Haut.qml` |
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

- Bouton NexusOS, champ « Rechercher » ou Super+Espace : ouvrent le menu Démarrer.
- Clic sur une application : l'ouvre, ou affiche sa fenêtre si elle est déjà ouverte (trait bleu dessous).
- Voir les erreurs : ouvrir un terminal dans la VM et taper `pkill quickshell; quickshell`.
- Revenir à l'ancien dock :
  `sed -i 's/^exec-once = quickshell$/exec-once = nwg-dock-hyprland -x -i 40 -mb 14/' ~/.config/hypr/hyprland.conf` puis redémarrer.

## Menu Démarrer (Quickshell)

- Recherche : taper directement, Entrée lance le premier résultat, Échap ferme.
- Accueil : Épinglé (12 applications), Récents (fichiers ouverts récemment), Recommandé (Jeux, Création, Bureau).
- À gauche : Applications, dossiers personnels, Alimentation (verrouiller, déconnexion, redémarrer, éteindre).
- Réglages en haut de `config/quickshell/Menu.qml` (applications épinglées, cartes recommandées) ;
  applications masquées dans `config/quickshell/Etat.qml`.
- Ouvrir depuis un raccourci : `quickshell ipc call menu basculer`.

## Fenêtres (façon HyperOS)

- Trois points en haut au centre de la fenêtre active. Un clic ouvre une pastille :
  plein écran · moitié gauche · moitié droite · petite fenêtre flottante · fermer.
  Le bouton du mode actuel est allumé en bleu. « Plein écran » sur une fenêtre flottante la remet en place.
- Clavier : Super+Q fermer, Super+F plein écran, Super+V fenêtre flottante (déplaçable avec Super + clic gauche).
- Applications GTK (gestionnaire de fichiers…) en mode sombre : `config/gtk-3.0/settings.ini`.

## Barre du haut et îlot (Quickshell, remplace Waybar)

- Îlot central : anneau animé pendant la connexion, « Connecté » + nom du réseau, Bluetooth, clé USB, volume, batterie.
- Clic sur le texte du réseau : réglages réseau. Clic sur le volume : réglages du son.
  Molette sur la droite de l'îlot : volume ; clic molette : couper / remettre le son.
- Les informations viennent de `config/quickshell/etat.sh` (relu toutes les 3 secondes).
- Waybar reste installé : pour y revenir, ajouter `exec-once = waybar` dans hyprland.conf
  et retirer `Haut {}` de `config/quickshell/shell.qml`.

## Icônes de bureau, logo et écran de connexion

- Icônes à gauche (double-clic) : Ce PC, Corbeille, Dossiers perso, Cloud (bientôt), Paramètres (bientôt),
  NexusOS (infos système), Jeux, Applications. Liste dans `config/quickshell/Bureau.qml`.
- Logo NexusOS : `logos/nexusos.svg` (version « Orbite »), aussi sur le bouton du menu.
- Écran de connexion : `sddm/nexusos/` installé dans `/usr/share/sddm/themes/nexusos`.
  Revenir à l'ancien : `sudo rm /etc/sddm.conf.d/10-nexusos.conf` puis redémarrer.

## Divers

- Infos système (`fastfetch`, icône NexusOS du bureau) : nom NexusOS et logo Orbite, `config/fastfetch/`.
- Résolution de la VM : ligne `monitor` dans `~/.config/hypr/machine.conf` (1920x1080 par défaut).
- Les trois points de la poignée sont dans l'espace au-dessus de la fenêtre, pour ne pas cacher son contenu.

## Infos système (icône NexusOS)

- fastfetch avec le logo Orbite en caractères et « NexusOS (base Arch Linux) » :
  `config/fastfetch/config.jsonc` et `config/fastfetch/nexusos.txt`.

## Fluidité dans VirtualBox

- En option, effets allégés dans VirtualBox (flou léger, sans ombres, animations courtes) :
  `NEXUS_ALLEGER=1 bash install_theme_nexusos.sh`. Sans cette option, effets complets.
- Gestion de la mémoire (zram, earlyoom) : `outils/optimisation_memoire.sh` à la racine du dépôt.

## Icônes du bureau

- Dessinées pour NexusOS (dégradés bleu/violet) : `config/quickshell/icones/*.svg`.

## Paramètres NexusOS (Super+I)

- Fenêtre Quickshell organisée par groupes (façon HyperOS) :
  Accueil · Bluetooth et appareils, Réseau et Internet, Plus d'options de connexion · Applications, Jeux ·
  Écran, Son, Notifications, Fond d'écran et thème · Comptes, Heure et langue, Sécurité, Batterie ·
  Mise à jour et sauvegarde, À propos.
- Fichiers : `config/quickshell/Parametres.qml` (fenêtre et organisation), `Page*.qml` (une page par catégorie),
  `P*.qml` (cartes, lignes, interrupteurs, curseurs), `nexus-param.py` (lit et règle le système).
- Réglages gardés : `~/.config/nexusos/fond`, `~/.config/nexusos/epingles.json`, `~/.config/hypr/ecran.conf`.
- Les réglages système (SSH, snapshot) demandent le mot de passe via hyprpolkitagent.
- Ouvrir depuis un terminal : `quickshell ipc call parametres ouvrir` ou `quickshell ipc call parametres page son`.
