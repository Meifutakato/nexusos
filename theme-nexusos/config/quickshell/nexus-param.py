#!/usr/bin/env python3
"""NexusOS — petit programme utilisé par la fenêtre Paramètres.

Lecture  : python3 nexus-param.py <sujet>          → une ligne JSON
Action   : python3 nexus-param.py <action> [args]   → une ligne JSON {"ok": ..., "message": ...}

Aucune dépendance en dehors de Python et des outils du système (nmcli, bluetoothctl,
wpctl/pactl, hyprctl, systemctl...). Si un outil manque, la réponse le dit au lieu de planter.
"""
import json
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

MAISON = Path.home()
CONF_NEXUS = MAISON / ".config" / "nexusos"
FICHIER_FOND = CONF_NEXUS / "fond"
FICHIER_EPINGLES = CONF_NEXUS / "epingles.json"
FICHIER_ECRAN = MAISON / ".config" / "hypr" / "ecran.conf"
FOND_DEFAUT = "/usr/share/backgrounds/nexusos/galaxie-nexus.jpg"


def lancer(cmd, delai=8, entree=None):
    """Exécute une commande et renvoie (code, sortie). Ne lève jamais d'exception."""
    try:
        env = dict(os.environ, LC_ALL="C")
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=delai, input=entree, env=env)
        return r.returncode, (r.stdout or "") + (r.stderr if r.returncode else "")
    except FileNotFoundError:
        return 127, "absent"
    except subprocess.TimeoutExpired:
        return 124, "trop long"
    except Exception as e:  # noqa: BLE001
        return 1, str(e)


def existe(prog):
    return shutil.which(prog) is not None


def sortir(obj):
    print(json.dumps(obj, ensure_ascii=False), flush=True)


def ok(message="", **extra):
    sortir(dict(ok=True, message=message, **extra))


def echec(message):
    sortir(dict(ok=False, message=message))


# ─────────────────────────── LECTURES ───────────────────────────

def lire_infos():
    def fichier(p, defaut=""):
        try:
            return Path(p).read_text().strip()
        except OSError:
            return defaut

    cpu = ""
    for ligne in fichier("/proc/cpuinfo").splitlines():
        if ligne.startswith("model name"):
            cpu = ligne.split(":", 1)[1].strip()
            break
    coeurs = os.cpu_count() or 0
    mem = {}
    for ligne in fichier("/proc/meminfo").splitlines():
        k, _, v = ligne.partition(":")
        mem[k] = int(v.split()[0]) if v.split() else 0
    total = mem.get("MemTotal", 0) * 1024
    dispo = mem.get("MemAvailable", 0) * 1024
    st = os.statvfs("/")
    disque_total = st.f_blocks * st.f_frsize
    disque_libre = st.f_bavail * st.f_frsize
    try:
        secondes = float(fichier("/proc/uptime", "0").split()[0])
    except ValueError:
        secondes = 0
    _, virt = lancer(["systemd-detect-virt"])
    virt = virt.strip()
    modele = fichier("/sys/class/dmi/id/product_name")
    if virt == "oracle":
        modele = "VirtualBox"
    gpu = ""
    code, sortie = lancer(["lspci"])
    if code == 0:
        for l in sortie.splitlines():
            if "VGA" in l or "3D controller" in l or "Display" in l:
                gpu = l.split(":", 2)[-1].strip()
                break
    snapshots = 0
    try:
        snapshots = len([p for p in Path("/.snapshots").iterdir()])
    except OSError:
        pass
    nom_complet = ""
    try:
        import pwd
        nom_complet = pwd.getpwuid(os.getuid()).pw_gecos.split(",")[0]
    except Exception:  # noqa: BLE001
        pass
    sortir({
        "hote": os.uname().nodename,
        "utilisateur": os.environ.get("USER", ""),
        "nomComplet": nom_complet,
        "noyau": os.uname().release,
        "processeur": cpu,
        "coeurs": coeurs,
        "gpu": gpu,
        "modele": modele or "PC",
        "ramTotale": total,
        "ramUtilisee": max(0, total - dispo),
        "disqueTotal": disque_total,
        "disqueUtilise": max(0, disque_total - disque_libre),
        "allumeDepuis": int(secondes),
        "snapshots": snapshots,
        "derniereMaj": derniere_maj(),
        "photo": (MAISON / ".face").exists(),
    })


def derniere_maj():
    """Date de la dernière mise à jour complète (journal de pacman)."""
    try:
        derniere = ""
        with open("/var/log/pacman.log", errors="replace") as f:
            for ligne in f:
                if "starting full system upgrade" in ligne:
                    derniere = ligne
        m = re.match(r"\[([0-9T:\-+]+)\]", derniere)
        return m.group(1) if m else ""
    except OSError:
        return ""


def lire_reseau():
    if not existe("nmcli"):
        sortir({"disponible": False})
        return
    _, radio = lancer(["nmcli", "radio", "wifi"])
    connexions = []
    _, s = lancer(["nmcli", "-t", "-f", "NAME,TYPE,DEVICE,STATE", "connection", "show", "--active"])
    for l in s.splitlines():
        parts = re.split(r"(?<!\\):", l)
        if len(parts) >= 4 and parts[1] not in ("loopback",):
            connexions.append({"nom": parts[0].replace("\\:", ":"), "type": parts[1], "appareil": parts[2], "etat": parts[3]})
    reseaux = []
    _, s = lancer(["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "auto"], delai=12)
    vus = set()
    for l in s.splitlines():
        parts = re.split(r"(?<!\\):", l)
        if len(parts) < 4 or not parts[1] or parts[1] in vus:
            continue
        vus.add(parts[1])
        reseaux.append({"actif": parts[0] == "*", "ssid": parts[1].replace("\\:", ":"),
                        "signal": int(parts[2] or 0), "securite": parts[3]})
    reseaux.sort(key=lambda r: (not r["actif"], -r["signal"]))
    _, ip = lancer(["ip", "-4", "-o", "addr", "show", "scope", "global"])
    adresse = ""
    m = re.search(r"inet ([0-9.]+)", ip)
    if m:
        adresse = m.group(1)
    sortir({"disponible": True, "wifiActif": radio.strip() == "enabled", "connexions": connexions,
            "reseaux": reseaux[:20], "ip": adresse})


def lire_bluetooth():
    if not existe("bluetoothctl"):
        sortir({"adaptateur": False, "raison": "bluetoothctl n'est pas installé"})
        return
    code, s = lancer(["bluetoothctl", "show"])
    if code != 0 or "Controller" not in s:
        sortir({"adaptateur": False, "raison": "Aucun adaptateur Bluetooth détecté"})
        return
    allume = "Powered: yes" in s
    appareils = []
    _, liste = lancer(["bluetoothctl", "devices", "Paired"])
    for l in liste.splitlines():
        m = re.match(r"Device ([0-9A-F:]{17}) (.*)", l.strip())
        if m:
            _, info = lancer(["bluetoothctl", "info", m.group(1)])
            appareils.append({"adresse": m.group(1), "nom": m.group(2),
                              "connecte": "Connected: yes" in info})
    sortir({"adaptateur": True, "allume": allume, "appareils": appareils})


def lire_son():
    sorties, entrees = [], []
    defaut_sortie = defaut_entree = ""
    if existe("pactl"):
        _, d = lancer(["pactl", "get-default-sink"])
        defaut_sortie = d.strip()
        _, d = lancer(["pactl", "get-default-source"])
        defaut_entree = d.strip()
        for genre, cible in (("sinks", sorties), ("sources", entrees)):
            code, s = lancer(["pactl", "-f", "json", "list", genre])
            if code == 0:
                try:
                    for e in json.loads(s):
                        if genre == "sources" and e.get("monitor_source") == "" and ".monitor" in e.get("name", ""):
                            continue
                        if ".monitor" in e.get("name", ""):
                            continue
                        vols = [int(str(c.get("value_percent", "0")).rstrip("%") or 0)
                                for c in (e.get("volume") or {}).values()]
                        cible.append({"nom": e.get("name", ""), "description": e.get("description", e.get("name", "")),
                                      "volume": max(vols) if vols else 0, "muet": bool(e.get("mute"))})
                except (ValueError, TypeError, AttributeError):
                    pass
    volume, muet = -1, False
    code, s = lancer(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"])
    m = re.search(r"([0-9.]+)", s)
    if code == 0 and m:
        volume = round(float(m.group(1)) * 100)
        muet = "MUTED" in s
    micro, micro_muet = -1, False
    code, s = lancer(["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"])
    m = re.search(r"([0-9.]+)", s)
    if code == 0 and m:
        micro = round(float(m.group(1)) * 100)
        micro_muet = "MUTED" in s
    sortir({"volume": volume, "muet": muet, "micro": micro, "microMuet": micro_muet,
            "sorties": sorties, "entrees": entrees,
            "sortieDefaut": defaut_sortie, "entreeDefaut": defaut_entree})


def lire_ecran():
    code, s = lancer(["hyprctl", "monitors", "-j"])
    ecrans = []
    if code == 0:
        try:
            for m in json.loads(s):
                modes = []
                for mode in m.get("availableModes", []):
                    mm = re.match(r"(\d+)x(\d+)@([0-9.]+)Hz", mode)
                    if mm:
                        modes.append(f"{mm.group(1)}x{mm.group(2)}@{round(float(mm.group(3)))}")
                courantes = ["1280x720@60", "1366x768@60", "1600x900@60", "1920x1080@60", "2560x1440@60"]
                if m.get("model", "").lower().startswith("virtual") or not modes:
                    modes = modes + [c for c in courantes if c not in modes]
                ecrans.append({
                    "nom": m.get("name"), "description": m.get("description", ""),
                    "largeur": m.get("width"), "hauteur": m.get("height"),
                    "frequence": round(m.get("refreshRate", 60)), "echelle": m.get("scale", 1),
                    "modes": sorted(set(modes), key=lambda x: -int(x.split("x")[0]) * int(x.split("x")[1].split("@")[0])),
                })
        except ValueError:
            pass
    sortir({"ecrans": ecrans})


def lire_options():
    vpn = []
    if existe("nmcli"):
        _, s = lancer(["nmcli", "-t", "-f", "NAME,TYPE,ACTIVE", "connection", "show"])
        for l in s.splitlines():
            p = l.split(":")
            if len(p) >= 3 and p[1] in ("vpn", "wireguard"):
                vpn.append({"nom": p[0], "type": p[1], "actif": p[2] == "yes"})
    _, actif = lancer(["systemctl", "is-active", "sshd"])
    _, active_demarrage = lancer(["systemctl", "is-enabled", "sshd"])
    partage = False
    if existe("nmcli"):
        _, s = lancer(["nmcli", "-t", "-f", "NAME,ACTIVE", "connection", "show"])
        partage = any(l.startswith("Hotspot:yes") for l in s.splitlines())
    sortir({"vpn": vpn, "ssh": actif.strip() == "active", "sshDemarrage": active_demarrage.strip() == "enabled",
            "partage": partage, "nmcli": existe("nmcli")})


def lire_jeux():
    def installe(*noms):
        return any(existe(n) for n in noms) or any(
            Path(d, n + ".desktop").exists() for d in ("/usr/share/applications", str(MAISON / ".local/share/applications"))
            for n in noms)
    lanceurs = [
        {"id": "steam", "nom": "Steam", "installe": installe("steam")},
        {"id": "com.heroicgameslauncher.hgl", "nom": "Heroic (Epic, GOG)", "installe": installe("heroic", "com.heroicgameslauncher.hgl")},
        {"id": "net.lutris.Lutris", "nom": "Lutris", "installe": installe("lutris", "net.lutris.Lutris")},
    ]
    gamemode = existe("gamemoded")
    _, s = lancer(["systemctl", "--user", "is-active", "gamemoded"])
    clips = ""
    for c in (Path("/gameclips"), MAISON / "GameClips", MAISON / "Vidéos" / "Clips", MAISON / "Videos"):
        if c.exists():
            clips = str(c)
            break
    sortir({"lanceurs": lanceurs, "gamemode": gamemode, "gamemodeActif": s.strip() == "active", "clips": clips})


def lire_notifications():
    _, s = lancer(["dunstctl", "is-paused"])
    _, n = lancer(["dunstctl", "count", "history"])
    sortir({"nePasDeranger": s.strip() == "true", "historique": int(n.strip() or 0) if n.strip().isdigit() else 0,
            "disponible": existe("dunstctl")})


def lire_fonds():
    fonds = []
    dossiers = [Path("/usr/share/backgrounds"), MAISON / "Images", MAISON / "Pictures", MAISON / "Images" / "Fonds"]
    for d in dossiers:
        if not d.exists():
            continue
        for p in sorted(d.rglob("*")):
            if p.suffix.lower() in (".jpg", ".jpeg", ".png", ".webp") and p.is_file():
                if str(p) not in fonds:
                    fonds.append(str(p))
            if len(fonds) >= 40:
                break
    actuel = FOND_DEFAUT
    try:
        actuel = FICHIER_FOND.read_text().strip() or FOND_DEFAUT
    except OSError:
        pass
    sortir({"fonds": fonds, "actuel": actuel})


def lire_heure():
    _, s = lancer(["timedatectl", "show"])
    v = dict(l.split("=", 1) for l in s.splitlines() if "=" in l)
    _, loc = lancer(["localectl", "status"])
    clavier = ""
    m = re.search(r"X11 Layout: (\S+)", loc)
    if m:
        clavier = m.group(1)
    sortir({"fuseau": v.get("Timezone", ""), "ntp": v.get("NTP", "") == "yes",
            "synchro": v.get("NTPSynchronized", "") == "yes", "langue": os.environ.get("LANG", ""),
            "clavier": clavier})


def lire_batterie():
    for b in sorted(Path("/sys/class/power_supply").glob("BAT*")):
        def f(n):
            try:
                return (b / n).read_text().strip()
            except OSError:
                return ""
        sortir({"presente": True, "niveau": int(f("capacity") or 0), "etat": f("status"),
                "sante": f("capacity_level")})
        return
    sortir({"presente": False})


def lire_snapshots():
    liste = []
    try:
        for p in Path("/.snapshots").iterdir():
            try:
                liste.append({"nom": p.name, "date": int(p.stat().st_mtime)})
            except OSError:
                pass
    except OSError:
        pass
    liste.sort(key=lambda s: -s["date"])
    sortir({"snapshots": liste[:30]})


# ─────────────────────────── ACTIONS ───────────────────────────

def act_volume(valeur):
    v = max(0, min(150, int(float(valeur))))
    code, s = lancer(["wpctl", "set-volume", "-l", "1.5", "@DEFAULT_AUDIO_SINK@", f"{v}%"])
    ok() if code == 0 else echec(s)


def act_micro(valeur):
    v = max(0, min(100, int(float(valeur))))
    code, s = lancer(["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", f"{v}%"])
    ok() if code == 0 else echec(s)


def act_muet(quoi):
    cible = "@DEFAULT_AUDIO_SOURCE@" if quoi == "micro" else "@DEFAULT_AUDIO_SINK@"
    code, s = lancer(["wpctl", "set-mute", cible, "toggle"])
    ok() if code == 0 else echec(s)


def act_sortie(nom):
    code, s = lancer(["pactl", "set-default-sink", nom])
    ok("Sortie changée") if code == 0 else echec(s)


def act_entree(nom):
    code, s = lancer(["pactl", "set-default-source", nom])
    ok("Micro changé") if code == 0 else echec(s)


def act_wifi(etat):
    code, s = lancer(["nmcli", "radio", "wifi", "on" if etat == "on" else "off"])
    ok() if code == 0 else echec(s)


def act_connecter(ssid, mdp=""):
    cmd = ["nmcli", "device", "wifi", "connect", ssid]
    if mdp:
        cmd += ["password", mdp]
    code, s = lancer(cmd, delai=40)
    ok(f"Connecté à {ssid}") if code == 0 else echec("Connexion impossible : mot de passe incorrect ou réseau hors de portée")


def act_bluetooth(etat):
    code, s = lancer(["bluetoothctl", "power", "on" if etat == "on" else "off"])
    ok() if code == 0 else echec(s)


def act_appareil(adresse, etat):
    code, s = lancer(["bluetoothctl", "connect" if etat == "on" else "disconnect", adresse], delai=20)
    ok() if code == 0 else echec("L'appareil ne répond pas")


def act_vpn(nom, etat):
    code, s = lancer(["nmcli", "connection", "up" if etat == "on" else "down", nom], delai=30)
    ok() if code == 0 else echec(s)


def act_ssh(etat):
    # pkexec affiche la fenêtre de mot de passe (agent polkit)
    action = ["enable", "--now"] if etat == "on" else ["disable", "--now"]
    code, s = lancer(["pkexec", "systemctl", *action, "sshd"], delai=120)
    ok() if code == 0 else echec("Autorisation refusée ou annulée")


def act_partage(etat, mdp=""):
    if etat == "on":
        if len(mdp) < 8:
            echec("Le mot de passe doit faire au moins 8 caractères")
            return
        code, s = lancer(["nmcli", "device", "wifi", "hotspot", "ssid", "NexusOS", "password", mdp], delai=30)
    else:
        code, s = lancer(["nmcli", "connection", "down", "Hotspot"], delai=20)
    ok() if code == 0 else echec("Partage impossible (il faut une carte Wi-Fi)")


def act_ecran(nom, mode, echelle="1"):
    regle = f"{nom},{mode},auto,{echelle}"
    code, s = lancer(["hyprctl", "keyword", "monitor", regle])
    if code != 0:
        echec(s)
        return
    # Garder le réglage après redémarrage (fichier lu par hyprland.conf)
    FICHIER_ECRAN.parent.mkdir(parents=True, exist_ok=True)
    FICHIER_ECRAN.write_text(f"# Écrit par les Paramètres NexusOS\nmonitor = {regle}\n")
    ok("Écran réglé")


def act_nepasderanger(etat):
    code, s = lancer(["dunstctl", "set-paused", "true" if etat == "on" else "false"])
    ok() if code == 0 else echec(s)


def act_effacer_notifs():
    lancer(["dunstctl", "history-clear"])
    lancer(["dunstctl", "close-all"])
    ok("Notifications effacées")


def act_fond(chemin):
    if not Path(chemin).is_file():
        echec("Image introuvable")
        return
    CONF_NEXUS.mkdir(parents=True, exist_ok=True)
    FICHIER_FOND.write_text(chemin + "\n")
    lancer(["pkill", "-x", "swaybg"])
    subprocess.Popen(["swaybg", "-i", chemin, "-m", "fill"], stdout=subprocess.DEVNULL,
                     stderr=subprocess.DEVNULL, start_new_session=True)
    ok("Fond d'écran changé")


def act_epingles(cible, liste_json):
    try:
        liste = json.loads(liste_json)
        assert isinstance(liste, list)
    except (ValueError, AssertionError):
        echec("Liste invalide")
        return
    donnees = {}
    try:
        donnees = json.loads(FICHIER_EPINGLES.read_text())
    except (OSError, ValueError):
        pass
    donnees[cible] = liste
    CONF_NEXUS.mkdir(parents=True, exist_ok=True)
    tmp = FICHIER_EPINGLES.with_suffix(".tmp")
    tmp.write_text(json.dumps(donnees, ensure_ascii=False, indent=2))
    tmp.replace(FICHIER_EPINGLES)
    ok()


def act_hote(nom):
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9-]{0,62}", nom):
        echec("Nom invalide : lettres, chiffres et tirets seulement")
        return
    code, s = lancer(["hostnamectl", "set-hostname", nom], delai=120)
    ok("Nom du PC changé") if code == 0 else echec("Autorisation refusée ou annulée")


def act_snapshot():
    nom = "/.snapshots/manuel-" + time.strftime("%Y-%m-%d_%H%M")
    code, s = lancer(["pkexec", "btrfs", "subvolume", "snapshot", "-r", "/", nom], delai=120)
    ok("Snapshot créé : " + Path(nom).name) if code == 0 else echec("Autorisation refusée ou annulée")


def act_ntp(etat):
    code, s = lancer(["timedatectl", "set-ntp", "true" if etat == "on" else "false"], delai=120)
    ok() if code == 0 else echec("Autorisation refusée ou annulée")


LECTURES = {
    "infos": lire_infos, "reseau": lire_reseau, "bluetooth": lire_bluetooth, "son": lire_son,
    "ecran": lire_ecran, "options": lire_options, "jeux": lire_jeux, "notifications": lire_notifications,
    "fonds": lire_fonds, "heure": lire_heure, "batterie": lire_batterie, "snapshots": lire_snapshots,
}
ACTIONS = {
    "volume": act_volume, "micro": act_micro, "muet": act_muet, "sortie": act_sortie, "entree": act_entree,
    "wifi": act_wifi, "connecter": act_connecter, "bluetooth-etat": act_bluetooth, "appareil": act_appareil,
    "vpn": act_vpn, "ssh": act_ssh, "partage": act_partage, "ecran-mode": act_ecran,
    "nepasderanger": act_nepasderanger, "effacer-notifs": act_effacer_notifs, "fond": act_fond,
    "epingles": act_epingles, "hote": act_hote, "snapshot": act_snapshot, "ntp": act_ntp,
}


def main():
    if len(sys.argv) < 2:
        echec("usage : nexus-param.py <sujet|action> [arguments]")
        return
    nom, args = sys.argv[1], sys.argv[2:]
    try:
        if nom in LECTURES:
            LECTURES[nom]()
        elif nom in ACTIONS:
            ACTIONS[nom](*args)
        else:
            echec(f"inconnu : {nom}")
    except TypeError:
        echec("arguments manquants")
    except Exception as e:  # noqa: BLE001 — la fenêtre ne doit jamais rester sans réponse
        echec(str(e))


if __name__ == "__main__":
    main()
