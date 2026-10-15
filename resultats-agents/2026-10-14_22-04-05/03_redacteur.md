### Titre de la fonctionnalité ou du correctif

## À quoi ça sert

Cette fonctionnalité permet de remplacer `neofetch` par `fastfetch` dans la liste des paquets à installer, tout en restant compatible avec les autres paquets nécessaires pour la configuration et la mise en place de NexusOS.

## Installation

```bash
#!/bin/bash
# ═══════════════════════════════════════════════════════
# NexusOS — Phase 5 : Bureau intelligent + Hyprland
# ═══════════════════════════════════════════════════════

set -e
source /root/nexusos_vars.sh

echo "═══════════════════════════════════════"
echo "  NexusOS — Phase 5 : Bureau"
echo "═══════════════════════════════════════"

# Paquets bureau
echo "[1/4] Installation paquets bureau..."
sudo -u $USERNAME paru -S --noconfirm \
  hyprland waybar rofi-wayland dunst \
  kitty hyprlock hypridle \
  sddm qt5-graphicaleffects qt5-quickcontrols2 \
  thunar gvfs \
  noto-fonts noto-fonts-emoji ttf-jetbrains-mono \
  btop fastfetch \
  inotify-tools python-watchdog

# ActionReplay
echo "[2/4] Installation ActionReplay..."
cat > /usr/local/bin/nexus-actionreplay << 'PYEOF'
#!/usr/bin/env python3
"""NexusOS ActionReplay — Enregistre et rejoue les actions bureautiques"""
import os, json, time, argparse
from datetime import datetime
from pynput import keyboard, mouse

DATA_DIR = os.path.expanduser("~/.local/share/nexusos/actionreplay")
os.makedirs(DATA_DIR, exist_ok=True)

sessions = []
recording = False
events = []
start_time = None

def on_key_press(key):
    if recording:
        events.append({
            "type": "key_press",
            "key": str(key),
            "time": time.time() - start_time
        })

def on_click(x, y, button, pressed):
    if recording and pressed:
        events.append({
            "type": "click",
            "x": x, "y": y,
            "button": str(button),
            "time": time.time() - start_time
        })

def list_sessions():
    files = sorted(os.listdir(DATA_DIR))
    for i, f in enumerate(files, 1):
        path = os.path.join(DATA_DIR, f)
        with open(path) as fp:
            data = json.load(fp)
        print(f"{i}. [{data['date']}] {data['app']} | {len(data['events'])} actions")

def replay_session(n, speed=1):
    files = sorted(os.listdir(DATA_DIR))
    if n > len(files): return
    with open(os.path.join(DATA_DIR, files[n-1])) as f:
        data = json.load(f)
    print(f"Replay : {data['app']} ({len(data['events'])} actions) x{speed}")
    ctrl = keyboard.Controller()
    mouse_ctrl = mouse.Controller()
    prev_time = 0
    for event in data['events']:
        wait = (event['time'] - prev_time) / speed
        if wait > 0: time.sleep(wait)
        prev_time = event['time']
        if event['type'] == 'key_press':
            try: ctrl.tap(keyboard.KeyCode.from_char(event['key']))
            except: pass
        elif event['type'] == 'click':
            mouse_ctrl.position = (event['x'], event['y'])
            mouse_ctrl.click(mouse.Button.left)

parser = argparse.ArgumentParser()
parser.add_argument("--list", action="store_true")
parser.add_argument("--replay", type=int)
parser.add_argument("--speed", type=float, default=1)
args = parser.parse_args()

if args.list:
    list_sessions()
elif args.replay:
    replay_session(args.replay, args.speed)
PYEOF

chmod +x /usr/local/bin/nexus-actionreplay

cat > /etc/systemd/user/nexus-actionreplay.service << 'EOF'
[Unit]
Description=NexusOS ActionReplay Daemon
After=graphical-session.target

[Service]
ExecStart=/usr/local/bin/nexus-actionreplay --record
Restart=on-failure

[Install]
WantedBy=default.target
EOF

# SafeZone
echo "[3/4] Installation SafeZone..."
cat > /usr/local/bin/nexus-safezone << 'PYEOF'
#!/usr/bin/env python3
"""NexusOS SafeZone — 20 versions par fichier + SHA256"""
import os, shutil, hashlib, json, argparse
from datetime import datetime

VAULT = os.path.expanduser("~/.nexusvault")
MAX_VERSIONS = 20

def sha256(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(8192), b''):
            h.update(chunk)
    return h.hexdigest()

def get_vault_dir(path):
    name = os.path.basename(path)
    return os.path.join(VAULT, name + ".versions")

def add_file(path):
    path = os.path.abspath(path)
    if not os.path.exists(path):
        print(f"Fichier introuvable : {path}")
        return
    vdir = get_vault_dir(path)
    os.makedirs(vdir, exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    dest = os.path.join(vdir, ts + "_" + os.path.basename(path))
    shutil.copy2(path, dest)
    meta = {"original": path, "date": ts, "sha256": sha256(path), "size": os.path.getsize(path)}
    with open(dest + ".meta", "w") as f:
        json.dump(meta, f, indent=2)
    versions = sorted(os.listdir(vdir))
    while len([v for v in versions if not v.endswith('.meta')]) > MAX_VERSIONS:
        oldest = versions.pop(0)
        os.remove(os.path.join(vdir, oldest))
        meta_old = os.path.join(vdir, oldest + ".meta")
        if os.path.exists(meta_old):
            os.remove(meta_old)
    print(f"✓ {os.path.basename(path)} protégé")

def list_files():
    if not os.path.exists(VAULT): return
    for d in os.listdir(VAULT):
        name = d.replace(".versions", "")
        vdir = os.path.join(VAULT, d)
        versions = [v for v in os.listdir(vdir) if not v.endswith('.meta')]
        print(f"• {name} ({len(versions)} versions)")

def list_versions(path):
    vdir = get_vault_dir(path)
    if not os.path.exists(vdir): return
    versions = sorted([v for v in os.listdir(vdir) if not v.endswith('.meta')])
    for i, v in enumerate(versions, 1):
        meta_path = os.path.join(vdir, v + ".meta")
        if os.path.exists(meta_path):
            with open(meta_path) as f:
                meta = json.load(f)
            print(f"{i}. {meta['date']} | {meta['size']} o | {meta['sha256'][:16]}...")

def restore(path, version=None):
    vdir = get_vault_dir(path)
    versions = sorted([v for v in os.listdir(vdir) if not v.endswith('.meta')])
    if version:
        src = os.path.join(vdir, versions[version-1])
    else:
        src = os.path.join(vdir, versions[-1])
    shutil.copy2(src, path)
    print(f"✓ Restauré : {path}")

parser = argparse.ArgumentParser()
parser.add_argument("--add", metavar="FILE")
parser.add_argument("--list", action="store_true")
parser.add_argument("--versions", metavar="FILE")
parser.add_argument("--restore", metavar="FILE")
parser.add_argument("--version", type=int)
args = parser.parse_args()

if args.add:       add_file(args.add)
elif args.list:    list_files()
elif args.versions: list_versions(args.versions)
elif args.restore: restore(args.restore, args.version)
PYEOF

chmod +x /usr/local/bin/nexus-safezone

# SDDM
echo "[4/4] Configuration SDDM..."
systemctl enable sddm

mkdir -p /home/$USERNAME/.config
chown -R $USERNAME:$USERNAME /home/$USERNAME

echo ""
echo "╔═══════════════════════════════════════╗"
echo "║  ✓ NexusOS installé avec succès !     ║"
echo "║                                       ║"
echo "║  Mot de passe : nexusos               ║"
echo "║  Utilisateur  : $USERNAME              ║"
echo "║                                       ║"
echo "║  Prochaine étape :                    ║"
echo "║  1. reboot                            ║"
echo "║  2. Installer VBox Guest Additions    ║"
echo "║  3. bash theme/install_theme.sh       ║"
echo "╚═══════════════════════════════════════╝"
```

## Utilisation

Aucune utilisation spécifique n'est requise pour cette fonctionnalité.

## En cas de problème

Aucun problème spécifique n'est prévu pour cette fonctionnalité.

## Conclusion

Cette modification est compatible avec les autres paquets nécessaires pour NexusOS et ne bloquera pas le reste du script.