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
----- lignes 150 à 169 -----
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
>>>>>>> APRES

Expliqué : Le chemin du coffre VAULT a été modifié de `~/.nexusvault` à `/.nexusvault`.