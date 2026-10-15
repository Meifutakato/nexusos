FICHIER: phase5_desktop.sh
<<<<<<< AVANT
sudo -u $USERNAME paru -S --noconfirm \
  hyprland waybar rofi-wayland dunst \
=======
sudo -u "$USERNAME" paru -S --needed --noconfirm hyprland waybar kitty sddm

OPTIONNELS=(rofi-wayland dunst hyprlock hypridle thunar gvfs btop fastfetch)
ECHECS=()
for paquet in "${OPTIONNELS[@]}"; do
  sudo -u "$USERNAME" paru -S --needed --noconfirm "$paquet" || ECHECS+=("$paquet")
done
if (( ${#ECHECS[@]} > 0 )); then
  echo "⚠ Paquets optionnels non installés : ${ECHECS[*]}"
fi
>>>>>>> APRES

(Dans le vrai fichier, la partie AVANT doit couvrir TOUTES les lignes de l'ancienne commande paru,
jusqu'à la dernière ligne sans « \ ».)

## À retenir
- `|| ECHECS+=(...)` ou `|| echo "..."` empêche `set -e` d'arrêter le script.
- `--needed` évite de réinstaller ce qui est déjà là.
- Toujours `"$USERNAME"` entre guillemets.

FICHIER: phase5_desktop.sh
<<<<<<< AVANT
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

# SafeZone
echo "[3/4] Installation SafeZone..."
cat > /usr/local/bin/nexus-safezone << 'PYEOF'
#!/usr/bin/env python3
"""NexusOS SafeZone — 20 versions par fichier + SHA256"""
import os, shutil, hashlib, json, argparse
from datetime import datetime

VAULT = os.path.expanduser("/.nexusvault")
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
>>>>>>> APRES

(Dans le vrai fichier, la partie AVANT doit couvrir TOUTES les lignes de l'ancienne commande paru,
jusqu'à la dernière ligne sans « \ ».)

## À retenir
- `|| ECHECS+=(...)` ou `|| echo "..."` empêche `set -e` d'arrêter le script.
- `--needed` évite de réinstaller ce qui est déjà là.
- Toujours `"$USERNAME"` entre guillemets.