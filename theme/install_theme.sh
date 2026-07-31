#!/bin/bash
# ═══════════════════════════════════════════════════════
# NexusOS — Thème HyperOS / Hyprland
# Usage : bash install_theme.sh [username]
# ═══════════════════════════════════════════════════════

USERNAME=${1:-wylan}
HOME_DIR="/home/$USERNAME"
CONFIG="$HOME_DIR/.config"

echo "═══════════════════════════════════════"
echo "  NexusOS — Thème HyperOS"
echo "  Utilisateur : $USERNAME"
echo "═══════════════════════════════════════"

mkdir -p $CONFIG/{hypr,waybar,rofi,dunst,kitty,gtk-3.0}

# ── Hyprland config ──────────────────────────────────
cat > $CONFIG/hypr/hyprland.conf << 'EOF'
# NexusOS — Hyprland HyperOS Theme

# ════ MONITEUR ════
monitor=,preferred,auto,1

# ════ VARIABLES ENV ════
env = XCURSOR_SIZE,24
env = QT_QPA_PLATFORM,wayland
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland

# ════ AUTOSTART ════
exec-once = waybar
exec-once = dunst
exec-once = hyprpaper
exec-once = hypridle
exec-once = systemctl --user start nexus-shadowrecord
exec-once = systemctl --user start nexus-actionreplay

# ════ INPUT ════
input {
    kb_layout = fr
    follow_mouse = 1
    touchpad { natural_scroll = true }
    sensitivity = 0
}

# ════ GÉNÉRAL ════
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(6ee7f7ff) rgba(3b82f6ff) 45deg
    col.inactive_border = rgba(1d2130aa)
    layout = dwindle
}

# ════ DÉCORATION ════
decoration {
    rounding = 12
    active_opacity = 1.0
    inactive_opacity = 0.92
    drop_shadow = true
    shadow_range = 20
    shadow_render_power = 3
    col.shadow = rgba(00000055)

    blur {
        enabled = true
        size = 8
        passes = 3
        noise = 0.02
        vibrancy = 0.2
    }
}

# ════ ANIMATIONS ════
animations {
    enabled = true
    bezier = spring, 0.34, 1.56, 0.64, 1
    bezier = ios, 0.25, 0.46, 0.45, 0.94
    bezier = hyper, 0.16, 1, 0.3, 1

    animation = windows, 1, 5, spring, popin 80%
    animation = windowsOut, 1, 4, ios, popin 80%
    animation = border, 1, 10, default
    animation = workspaces, 1, 5, hyper, slidefade 20%
    animation = fade, 1, 5, ios
}

# ════ LAYOUT ════
dwindle {
    pseudotile = true
    preserve_split = true
}

# ════ RÈGLES GAMING ════
windowrulev2 = noblur, class:^(steam_app_.*)$
windowrulev2 = noshadow, class:^(steam_app_.*)$
windowrulev2 = immediate, class:^(steam_app_.*)$
windowrulev2 = nodim, class:^(steam_app_.*)$
windowrulev2 = fullscreen, class:^(steam_app_.*)$

# ════ RACCOURCIS ════
$mod = SUPER

bind = $mod, Return, exec, kitty
bind = $mod, Space, exec, rofi -show drun
bind = $mod, Q, killactive
bind = $mod, F, fullscreen
bind = $mod SHIFT, L, exec, hyprlock
bind = $mod, 1, workspace, 1
bind = $mod, 2, workspace, 2
bind = $mod, 3, workspace, 3
bind = $mod, 4, workspace, 4
bind = $mod, 5, workspace, 5
bind = $mod SHIFT, 1, movetoworkspace, 1
bind = $mod SHIFT, 2, movetoworkspace, 2
bind = $mod SHIFT, 3, movetoworkspace, 3

# NexusOS shortcuts
bind = $mod, G, exec, nexus-gameresume --list
bind = $mod SHIFT, G, exec, kill -USR1 $(pgrep nexus-shadowrecord)
bind = $mod, S, exec, nexus-safezone --list
bind = $mod SHIFT, S, exec, nexus-actionreplay --list

# Screenshot
bind = , Print, exec, grim ~/Pictures/screenshot_$(date +%Y%m%d_%H%M%S).png
bind = SHIFT, Print, exec, grim -g "$(slurp)" ~/Pictures/screenshot_$(date +%Y%m%d_%H%M%S).png

# Souris
bindm = $mod, mouse:272, movewindow
bindm = $mod, mouse:273, resizewindow
EOF

# ── Config VirtualBox (à sourcer si nécessaire) ───────
cat > $CONFIG/hypr/vbox.conf << 'EOF'
# NexusOS — Ajustements VirtualBox
# Décommentez si écran noir dans VirtualBox :
# env = WLR_RENDERER_ALLOW_SOFTWARE,1
# env = LIBGL_ALWAYS_SOFTWARE,1
# env = WLR_NO_HARDWARE_CURSORS,1
EOF

# ── Waybar ────────────────────────────────────────────
cat > $CONFIG/waybar/config.jsonc << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 36,
    "spacing": 4,
    "modules-left": ["hyprland/workspaces", "hyprland/window"],
    "modules-center": ["clock"],
    "modules-right": ["custom/nexus", "network", "cpu", "memory", "battery", "tray"],

    "hyprland/workspaces": {
        "format": "{icon}",
        "format-icons": {
            "1": "󰈹", "2": "󰨞", "3": "󰍹",
            "active": "󰮯", "default": "󰊠"
        }
    },

    "clock": {
        "format": "󰃰 {:%H:%M  %d/%m/%Y}",
        "tooltip-format": "{calendar}"
    },

    "cpu": {
        "format": "󰻠 {usage}%",
        "interval": 2
    },

    "memory": {
        "format": "󰍛 {used:.1f}G",
        "interval": 5
    },

    "network": {
        "format-wifi": "󰤨 {signalStrength}%",
        "format-ethernet": "󰈀 {ipaddr}",
        "format-disconnected": "󰤭 Off"
    },

    "battery": {
        "format": "{icon} {capacity}%",
        "format-icons": ["󰁺","󰁻","󰁼","󰁽","󰁾","󰁿","󰂀","󰂁","󰂂","󰁹"]
    },

    "custom/nexus": {
        "format": "󰮯 NexusOS",
        "tooltip": true,
        "tooltip-format": "ShadowRecord: actif\nSafeZone: actif\nActionReplay: actif"
    },

    "tray": { "spacing": 8 }
}
EOF

cat > $CONFIG/waybar/style.css << 'EOF'
* {
    font-family: "JetBrains Mono", monospace;
    font-size: 13px;
    border: none;
    border-radius: 0;
}

window#waybar {
    background: rgba(13, 15, 20, 0.85);
    color: #e2e8f8;
    border-bottom: 1px solid rgba(110, 231, 247, 0.15);
}

.modules-left, .modules-center, .modules-right {
    background: transparent;
}

#workspaces button {
    padding: 0 8px;
    color: #4a5568;
    background: transparent;
    border-bottom: 2px solid transparent;
    transition: all 0.2s;
}

#workspaces button.active {
    color: #6ee7f7;
    border-bottom: 2px solid #6ee7f7;
    background: rgba(110, 231, 247, 0.08);
}

#clock {
    color: #e2e8f8;
    font-weight: 600;
}

#cpu { color: #a78bfa; }
#memory { color: #34d399; }
#network { color: #6ee7f7; }
#battery { color: #fbbf24; }

#custom-nexus {
    color: #6ee7f7;
    font-weight: 700;
    padding: 0 12px;
    background: rgba(110, 231, 247, 0.06);
    border-left: 2px solid rgba(110, 231, 247, 0.3);
}

tooltip {
    background: rgba(13, 15, 20, 0.95);
    border: 1px solid rgba(110, 231, 247, 0.2);
    color: #e2e8f8;
    border-radius: 8px;
}
EOF

# ── Rofi ──────────────────────────────────────────────
cat > $CONFIG/rofi/nexusos.rasi << 'EOF'
* {
    bg:      rgba(13, 15, 20, 0.95);
    fg:      #e2e8f8;
    accent:  #6ee7f7;
    muted:   #4a5568;
    font:    "JetBrains Mono 13";
}

window {
    width: 480px;
    background-color: @bg;
    border: 1px solid rgba(110, 231, 247, 0.25);
    border-radius: 12px;
    padding: 16px;
}

inputbar {
    background-color: rgba(110, 231, 247, 0.06);
    border: 1px solid rgba(110, 231, 247, 0.2);
    border-radius: 8px;
    padding: 10px 14px;
    margin-bottom: 12px;
}

entry { color: @fg; placeholder-color: @muted; }
prompt { color: @accent; margin-right: 8px; }

listview { spacing: 4px; }

element {
    padding: 9px 12px;
    border-radius: 6px;
    background-color: transparent;
    color: @muted;
}

element selected {
    background-color: rgba(110, 231, 247, 0.1);
    color: @accent;
}

element-icon { size: 20px; margin-right: 12px; }
element-text { color: inherit; }
EOF

# ── Dunst ─────────────────────────────────────────────
cat > $CONFIG/dunst/dunstrc << 'EOF'
[global]
monitor = 0
follow = mouse
width = 320
height = 120
origin = top-right
offset = 16x48
scale = 0
notification_limit = 5
progress_bar = true
transparency = 10
padding = 12
horizontal_padding = 14
corner_radius = 10
font = JetBrains Mono 12
format = "<b>%s</b>\n%b"
markup = full
show_age_threshold = 60
word_wrap = yes
browser = xdg-open

[urgency_low]
background = "#0d0f14"
foreground = "#6ee7f7"
frame_color = "#1d2130"
timeout = 4

[urgency_normal]
background = "#0d0f14"
foreground = "#e2e8f8"
frame_color = "#6ee7f7"
timeout = 6

[urgency_critical]
background = "#0d0f14"
foreground = "#f87171"
frame_color = "#f87171"
timeout = 0
EOF

# ── Kitty ─────────────────────────────────────────────
cat > $CONFIG/kitty/kitty.conf << 'EOF'
font_family      JetBrains Mono
font_size        13.0
background       #0d0f14
foreground       #e2e8f8
cursor           #6ee7f7
background_opacity 0.90
window_padding_width 14
confirm_os_window_close 0
enable_audio_bell no

# Couleurs NexusOS
color0  #1d2130
color1  #f87171
color2  #34d399
color3  #fbbf24
color4  #6ee7f7
color5  #a78bfa
color6  #60a5fa
color7  #e2e8f8
EOF

# ── GTK ───────────────────────────────────────────────
cat > $CONFIG/gtk-3.0/settings.ini << 'EOF'
[Settings]
gtk-theme-name = Adwaita-dark
gtk-icon-theme-name = Papirus-Dark
gtk-font-name = Inter 11
gtk-cursor-theme-name = Adwaita
gtk-application-prefer-dark-theme = 1
EOF

# ── Hyprlock ──────────────────────────────────────────
cat > $CONFIG/hypr/hyprlock.conf << 'EOF'
background {
    monitor =
    color = rgba(13, 15, 20, 1.0)
}

label {
    monitor =
    text = NexusOS
    color = rgba(110, 231, 247, 1.0)
    font_size = 48
    font_family = JetBrains Mono Bold
    position = 0, 100
    halign = center
    valign = center
}

input-field {
    monitor =
    size = 280, 48
    outline_thickness = 2
    outer_color = rgba(110, 231, 247, 0.4)
    inner_color = rgba(13, 15, 20, 0.9)
    font_color = rgb(226, 232, 248)
    fade_on_empty = true
    placeholder_text = Mot de passe
    position = 0, -60
    halign = center
    valign = center
}
EOF

# Permissions
chown -R $USERNAME:$USERNAME $HOME_DIR/.config

echo ""
echo "╔═══════════════════════════════════════════╗"
echo "║  ✓ Thème HyperOS installé !               ║"
echo "║                                           ║"
echo "║  Si VirtualBox → écran noir :             ║"
echo "║  Éditez ~/.config/hypr/vbox.conf          ║"
echo "║  et décommentez les 3 variables env       ║"
echo "║                                           ║"
echo "║  Redémarrez → choisir Hyprland dans SDDM  ║"
echo "╚═══════════════════════════════════════════╝"
