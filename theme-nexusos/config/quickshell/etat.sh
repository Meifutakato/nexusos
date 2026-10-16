#!/bin/sh
# NexusOS — état du système pour l'îlot du haut (lu toutes les 3 secondes par Quickshell)
# Sortie : une ligne de champs clé=valeur séparés par des tabulations.
export LC_ALL=C

# Réseau (NetworkManager si présent, sinon simple test de route)
reseau=aucun; etat=deconnecte; nom=""
if command -v nmcli >/dev/null 2>&1; then
    ligne=$(nmcli -t -f TYPE,STATE,CONNECTION device 2>/dev/null \
        | grep -E '^(wifi|ethernet):' | grep -v -E ':(unavailable|unmanaged)' | sort -t: -k2 | head -n1)
    if [ -n "$ligne" ]; then
        reseau=${ligne%%:*}; reste=${ligne#*:}; st=${reste%%:*}; nom=${reste#*:}
        case "$st" in
            connected*)  etat=connecte ;;
            connecting*) etat=connexion ;;
            *)           etat=deconnecte; nom="" ;;
        esac
    fi
fi
if [ "$etat" = deconnecte ] && ip route get 1.1.1.1 >/dev/null 2>&1; then
    etat=connecte; [ "$reseau" = aucun ] && reseau=ethernet
fi

# Batterie
bat=""; charge=""
for b in /sys/class/power_supply/BAT*; do
    if [ -r "$b/capacity" ]; then bat=$(cat "$b/capacity"); charge=$(cat "$b/status" 2>/dev/null); break; fi
done

# Bluetooth : absent / off / on
bt=absent
if ls /sys/class/bluetooth 2>/dev/null | grep -q hci; then
    bt=off
    if command -v bluetoothctl >/dev/null 2>&1 && bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then bt=on; fi
fi

# Clés USB branchées
usb=$(lsblk -dn -o TRAN 2>/dev/null | grep -c usb)

# Volume (ex. « Volume: 0.45 [MUTED] »)
vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)

printf 'reseau=%s\tetat=%s\tnom=%s\tbat=%s\tcharge=%s\tbt=%s\tusb=%s\tvol=%s\n' \
    "$reseau" "$etat" "$nom" "$bat" "$charge" "$bt" "$usb" "$vol"
