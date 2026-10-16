#!/bin/sh
# NexusOS — affiche le fond d'écran choisi dans Paramètres (sinon la galaxie NexusOS)
f=$(cat "$HOME/.config/nexusos/fond" 2>/dev/null)
[ -f "$f" ] || f=/usr/share/backgrounds/nexusos/galaxie-nexus.jpg
exec swaybg -i "$f" -m fill
