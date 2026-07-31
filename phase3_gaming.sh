#!/bin/bash
# ═══════════════════════════════════════════════════════
# NexusOS — Phase 3 : Gaming Layer
# ═══════════════════════════════════════════════════════

set -e
source /root/nexusos_vars.sh

echo "═══════════════════════════════════════"
echo "  NexusOS — Phase 3 : Gaming Layer"
echo "═══════════════════════════════════════"

# Activer multilib pour Steam
sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
pacman -Sy

# Paquets gaming
echo "[1/4] Installation paquets gaming..."
pacman -S --noconfirm \
  steam gamemode lib32-gamemode \
  mangohud lib32-mangohud \
  vulkan-radeon lib32-vulkan-radeon \
  vulkan-intel lib32-vulkan-intel \
  wine winetricks \
  ffmpeg python-pynput python-psutil \
  pipewire pipewire-pulse wireplumber

# Proton GE
echo "[2/4] Installation Proton GE..."
sudo -u $USERNAME paru -S --noconfirm proton-ge-custom-bin

# ShadowRecord — daemon Python buffer circulaire 5 min
echo "[3/4] Installation ShadowRecord..."
mkdir -p /home/$USERNAME/.gameclips/saved
mkdir -p /home/$USERNAME/.gameclips/buffer

cat > /usr/local/bin/nexus-shadowrecord << 'PYEOF'
#!/usr/bin/env python3
"""NexusOS ShadowRecord — Buffer circulaire 5 minutes"""
import os, signal, subprocess, json, time
from datetime import datetime
from collections import deque

BUFFER_MINUTES = 5
CLIPS_DIR = os.path.expanduser("~/.gameclips")
SAVED_DIR = os.path.join(CLIPS_DIR, "saved")
os.makedirs(SAVED_DIR, exist_ok=True)

buffer = deque(maxlen=BUFFER_MINUTES * 60)
recording = None
running = True

def get_active_game():
    try:
        result = subprocess.run(["pgrep", "-a", "wine"], capture_output=True, text=True)
        if result.stdout:
            return result.stdout.split("\n")[0].split()[-1].replace(".exe","")
    except: pass
    return "unknown_game"

def save_clip(signum=None, frame=None):
    game = get_active_game()
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    clip_name = f"{game}_clip_{ts}"
    clip_path = os.path.join(SAVED_DIR, clip_name + ".mp4")
    meta_path = os.path.join(SAVED_DIR, clip_name + "_metadata.json")

    subprocess.run([
        "ffmpeg", "-f", "x11grab", "-t", str(BUFFER_MINUTES * 60),
        "-i", ":0.0", "-c:v", "libx264", "-preset", "ultrafast",
        clip_path, "-y"
    ], capture_output=True)

    with open(meta_path, "w") as f:
        json.dump({
            "game": game,
            "timestamp": ts,
            "duration_minutes": BUFFER_MINUTES,
            "type": "manual_save"
        }, f, indent=2)
    print(f"✓ Clip sauvegardé : {clip_path}")

def crash_save(signum=None, frame=None):
    game = get_active_game()
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    clip_name = f"{game}_crash_{ts}"
    clip_path = os.path.join(SAVED_DIR, clip_name + ".mp4")
    meta_path = os.path.join(SAVED_DIR, clip_name + "_metadata.json")

    subprocess.run([
        "ffmpeg", "-f", "x11grab", "-t", "10",
        "-i", ":0.0", "-c:v", "libx264", "-preset", "ultrafast",
        clip_path, "-y"
    ], capture_output=True)

    with open(meta_path, "w") as f:
        json.dump({
            "game": game,
            "timestamp": ts,
            "type": "crash_detected"
        }, f, indent=2)
    print(f"✓ Crash sauvegardé : {clip_path}")

signal.signal(signal.SIGUSR1, save_clip)
signal.signal(signal.SIGUSR2, crash_save)

print("NexusOS ShadowRecord démarré — buffer 5 min actif")
while running:
    time.sleep(1)
PYEOF

chmod +x /usr/local/bin/nexus-shadowrecord

# Service systemd ShadowRecord
cat > /etc/systemd/user/nexus-shadowrecord.service << 'EOF'
[Unit]
Description=NexusOS ShadowRecord — Buffer gaming 5 min
After=graphical-session.target

[Service]
ExecStart=/usr/local/bin/nexus-shadowrecord
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

# GameResume
echo "[4/4] Installation GameResume..."
cat > /usr/local/bin/nexus-gameresume << 'PYEOF'
#!/usr/bin/env python3
"""NexusOS GameResume — Notes de session par jeu"""
import json, os, sys, argparse
from datetime import datetime

DATA_DIR = os.path.expanduser("~/.local/share/nexusos/gameresume")
os.makedirs(DATA_DIR, exist_ok=True)

def get_game_file(game):
    return os.path.join(DATA_DIR, game.replace(" ", "_") + ".json")

def load_game(game):
    f = get_game_file(game)
    if os.path.exists(f):
        with open(f) as fp:
            return json.load(fp)
    return {"game": game, "total_time": 0, "sessions": [], "notes": []}

def save_game(game, data):
    with open(get_game_file(game), "w") as f:
        json.dump(data, f, indent=2)

parser = argparse.ArgumentParser(description="NexusOS GameResume")
parser.add_argument("--game", help="Nom du jeu")
parser.add_argument("--show", action="store_true", help="Afficher les notes")
parser.add_argument("--add-note", help="Ajouter une note")
parser.add_argument("--list", action="store_true", help="Lister les jeux")
args = parser.parse_args()

if args.list:
    files = os.listdir(DATA_DIR)
    for f in files:
        print(f"• {f.replace('_', ' ').replace('.json', '')}")

elif args.game and args.show:
    data = load_game(args.game)
    print(f"\n🎮 {args.game}")
    print(f"Temps total : {data['total_time']} min")
    print(f"Sessions : {len(data['sessions'])}")
    print("\nDernières notes :")
    for note in data['notes'][-5:]:
        print(f"  [{note['date']}] {note['text']}")

elif args.game and args.add_note:
    data = load_game(args.game)
    data['notes'].append({
        "date": datetime.now().strftime("%Y-%m-%d %H:%M"),
        "text": args.add_note
    })
    save_game(args.game, data)
    print(f"✓ Note ajoutée pour {args.game}")
PYEOF

chmod +x /usr/local/bin/nexus-gameresume

# GameMode config
cat > /etc/gamemode.d/gamemode.ini << 'EOF'
[general]
desiredgov=performance
softrealtime=auto
renice=-20
ioprio=0
inhibit_screensaver=1

[gpu]
apply_gpu_optimisations=accept-responsibility
amd_performance_level=high
nv_powermizer_mode=1

[custom]
start=notify-send "NexusOS 🎮" "GameMode ACTIF"
end=notify-send "NexusOS" "GameMode désactivé"
EOF

chown -R $USERNAME:$USERNAME /home/$USERNAME/.gameclips

echo ""
echo "✓ Phase 3 terminée — Lancement phase 4..."
bash /root/phase4_network.sh
