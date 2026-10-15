FICHIER: phase5_desktop.sh
<<<<<<< AVANT
VAULT = os.path.expanduser("~/.nexusvault")
=======
VAULT = os.path.expanduser("/.nexusvault")
>>>>>>> APRES

FICHIER: phase5_desktop.sh
<<<<<<< AVANT
vdir = os.path.join(VAULT, d)
versions = [v for v in os.listdir(vdir) if not v.endswith('.meta')]
>>>>>>> APRES

FICHIER: phase5_desktop.sh
<<<<<<< AVANT
        oldest = versions.pop(0)
>>>>>>> APRES

FICHIER: phase5_desktop.sh
<<<<<<< AVANT
        os.remove(os.path.join(vdir, oldest))
>>>>>>> APRES

FICHIER: phase5_desktop.sh
<<<<<<< AVANT
        meta_old = os.path.join(vdir, oldest + ".meta")
>>>>>>> APRES

FICHIER: phase5_desktop.sh
<<<<<<< AVANT
        if os.path.exists(meta_old):
>>>>>>> APRES

FICHIER: phase5_desktop.sh
<<<<<<< AVANT
            os.remove(meta_old)
>>>>>>> APRES

FICHIER: phase5_desktop.sh
<<<<<<< AVANT
    print(f"✓ {os.path.basename(path)} protégé")
>>>>>>> APRES

FICHIER: phase5_desktop.sh
<<<<<<< AVANT
def list_files():
>>>>>>> APRES

FICHIER: phase5_desktop.sh
<<<<<<< AVANT
    if not os.path.exists(VAULT): return
>>>>>>> APRES

FICHIER: phase5_desktop.sh
<<<<<<< AVANT
    for d in os.listdir(VAULT):
>>>>>>> APRES

FICHIER: phase5_desktop.sh
<<<<<<< AVANT
        name = d.replace(".versions", "")
>>>>>>> APRES

FICHIER: phase5_desktop.sh
<<<<<<< AVANT
        vdir = os.path.join(VAULT, d)
>>>>>>> APRES

FICHIER: phase5_desktop.sh
<<<<<<< AVANT
        versions = [v for v in os.listdir(vdir) if not v.endswith('.meta')]
>>>>>>> APRES

FICHIER: phase5_desktop.sh
<<<<<<< AVANT
    print(f"• {name} ({len(versions)} versions)")
>>>>>>> APRES

FICHIER: phase5_desktop.sh
<<<<<<< AVANT
def list_versions(path):
>>>>>>> APRES

FICHIER: phase5_desktop.sh
<<<<<<< AVANT
    vdir = get_vault_dir(path)
>>>>>>> APRES

FICHIER: phase5_desktop.sh
<<<<<<< AVANT
    if not os.path.exists(vdir): return
>>>>>>> APRES

FICHIER: phase5_desktop.sh
<<<<<<< AVANT
    versions = sorted([v for v in os.listdir(vdir) if not v.endswith('.meta')])
>>>>>>> APRES

FICHIER: phase5_desktop.sh
<<<<<<< AVANT
    for i, v in enumerate(versions, 1):
>>>>>>> APRES

Explications :
- Les blocs de modification ont été ajoutés pour corriger les chemins vers le dossier de stockage du Vault dans SafeZone.
- Les chemins ont été modifiés de `~/.nexusvault` à `//.nexusvault` pour correspondre aux sous-volumes Btrfs définis dans le fichier `chemins et organisation de NexusOS.md`.
- Les fonctions `get_vault_dir`, `add_file`, `list_files`, `list_versions` ont été modifiées pour utiliser le nouveau chemin du Vault.