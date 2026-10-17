pragma Singleton
// NexusOS — état partagé entre la barre, le menu Démarrer et les Paramètres
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: etat

    property bool menuOuvert: false
    function basculerMenu() { menuOuvert = !menuOuvert; }

    // Ouvrir le menu directement sur une page ("applications" ou "categorie")
    property string pageDemandee: ""
    property string categorieDemandee: ""
    property string titreDemande: ""
    function ouvrirMenuSur(page, categorie, titre) {
        pageDemandee = page;
        categorieDemandee = categorie || "";
        titreDemande = titre || "";
        menuOuvert = true;
    }


    // ── Fenêtre Paramètres ──────────────────────────────────────
    property bool parametresOuverts: false
    property string pageParametres: "accueil"
    function ouvrirParametres(page) {
        pageParametres = page || "accueil";
        parametresOuverts = false;     // si la fenêtre a été fermée par le bureau, on la recrée
        parametresOuverts = true;
        menuOuvert = false;
    }

    // ── Emplacement pour le module IA (dossier ia-nexusos, installé à part) ──
    // Le thème ne contient aucune IA : si le module est installé, il dépose ses fichiers dans
    // ~/.config/quickshell/ia/ (avec module.json) et le groupe « Intelligence artificielle »
    // apparaît dans les Paramètres. Sinon, rien ne change.
    property bool iaInstalle: false
    FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/ia/module.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: etat.iaInstalle = true
        onLoadFailed: etat.iaInstalle = false
    }
    property bool assistantOuvert: false
    property string modeAssistant: "discussion"      // discussion, cv ou maquette
    function ouvrirAssistant(mode) {
        if (!iaInstalle) return;
        if (mode) modeAssistant = mode;
        assistantOuvert = false;
        assistantOuvert = true;
        menuOuvert = false;
    }
    // Commandes du module IA (nexus-ia), une à la fois, sans bloquer les autres réglages
    signal iaTerminee()
    property var fileIa: []
    readonly property bool iaOccupee: executeurIa.running
    function agirIa(args) {
        const f = fileIa.slice();
        f.push(args);
        fileIa = f;
        iaSuivante();
    }
    function iaSuivante() {
        if (executeurIa.running || fileIa.length === 0) return;
        const f = fileIa.slice();
        const a = f.shift();
        fileIa = f;
        executeurIa.command = ["nexus-ia"].concat(a);
        executeurIa.running = true;
    }
    Process {
        id: executeurIa
        stdout: SplitParser {
            onRead: ligne => {
                try {
                    const r = JSON.parse(ligne);
                    if (r.message) etat.notifier(r.message, r.ok);
                } catch (e) {}
            }
        }
        onExited: (code, statut) => {
            etat.iaTerminee();
            etat.iaSuivante();
        }
    }

    // Programme qui lit et règle le système pour les Paramètres
    readonly property string programmeParam: Quickshell.env("HOME") + "/.config/quickshell/nexus-param.py"

    // ── Applications épinglées (barre du bas et menu) ───────────
    // Réglables dans Paramètres › Applications ; enregistrées dans ~/.config/nexusos/epingles.json
    readonly property var epinglesBarreDefaut: [
        "thunar", "firefox", "microsoft-edge",
        "onlyoffice-desktopeditors",
        "libreoffice-writer", "libreoffice-calc", "libreoffice-impress",
        "kitty", "discord", "steam", "spotify",
        "heroic", "com.heroicgameslauncher.hgl", "org.pulseaudio.pavucontrol"
    ]
    readonly property var epinglesMenuDefaut: [
        "firefox", "microsoft-edge", "onlyoffice-desktopeditors",
        "libreoffice-writer", "libreoffice-calc", "libreoffice-impress",
        "thunar", "kitty", "org.gnome.Loupe", "ristretto", "steam", "discord",
        "spotify", "heroic", "com.heroicgameslauncher.hgl", "nexusos-lecteur", "btop", "org.pulseaudio.pavucontrol"
    ]
    property var epinglesFichier: ({})
    readonly property var listeBarre: Array.isArray(epinglesFichier.barre) ? epinglesFichier.barre : epinglesBarreDefaut
    readonly property var listeMenu: Array.isArray(epinglesFichier.menu) ? epinglesFichier.menu : epinglesMenuDefaut

    function enregistrerEpingles(cible, liste) {
        lancer(["python3", programmeParam, "epingles", cible, JSON.stringify(liste)]);
        const copie = Object.assign({}, epinglesFichier);
        copie[cible] = liste;
        epinglesFichier = copie;      // mise à jour immédiate, sans attendre le fichier
    }

    FileView {
        id: fichierEpingles
        path: Quickshell.env("HOME") + "/.config/nexusos/epingles.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try { etat.epinglesFichier = JSON.parse(text()) || {}; }
            catch (e) { etat.epinglesFichier = {}; }
        }
        onLoadFailed: etat.epinglesFichier = {}
    }


    // ── Actions des Paramètres (une à la fois, dans l'ordre) ────
    // Etat.agirParam(["volume", "40"]) → lance nexus-param.py, affiche son message,
    // puis émet actionParamTerminee() pour que la page se mette à jour.
    signal actionParamTerminee()
    property var fileParam: []
    property string messageParam: ""
    property bool messageOk: true
    property int numeroMessage: 0

    function agirParam(args) {
        const f = fileParam.slice();
        f.push(args);
        fileParam = f;
        actionSuivante();
    }
    function actionSuivante() {
        if (executeurParam.running || fileParam.length === 0) return;
        const f = fileParam.slice();
        const a = f.shift();
        fileParam = f;
        executeurParam.command = ["python3", programmeParam].concat(a);
        executeurParam.running = true;
    }
    function notifier(texte, reussi) {
        messageParam = texte;
        messageOk = reussi;
        numeroMessage++;
    }

    Process {
        id: executeurParam
        stdout: SplitParser {
            onRead: ligne => {
                try {
                    const r = JSON.parse(ligne);
                    if (r.message) etat.notifier(r.message, r.ok);
                } catch (e) {}
            }
        }
        onExited: (code, statut) => {
            etat.actionParamTerminee();
            etat.actionSuivante();
        }
    }


    // ── Petits outils d'affichage ───────────────────────────────
    function taille(octets) {
        if (!octets) return "0 Go";
        const go = octets / 1073741824;
        return (go >= 10 ? Math.round(go) : go.toFixed(1)).toString().replace(".", ",") + " Go";
    }
    function depuis(dateIso) {
        if (!dateIso) return "jamais";
        const ms = Date.now() - Date.parse(dateIso);
        if (isNaN(ms)) return "inconnu";
        const h = Math.floor(ms / 3600000);
        if (h < 1) return "il y a moins d'une heure";
        if (h < 24) return "il y a " + h + " h";
        const j = Math.floor(h / 24);
        return j === 1 ? "hier" : "il y a " + j + " jours";
    }

    // Icône d'une application : nom du thème d'icônes, ou chemin complet (/usr/share/pixmaps/…)
    function iconeAppli(icone) {
        const i = String(icone || "");
        if (i.indexOf("/") === 0) return "file://" + i;
        return Quickshell.iconPath(i, "application-x-executable");
    }

    // Logo NexusOS
    readonly property string logo: "file://" + Quickshell.env("HOME") + "/.config/quickshell/nexusos.svg"

    // Message « bientôt disponible »
    function bientot(quoi) {
        lancer(["notify-send", "NexusOS", quoi + " arrive bientôt."]);
    }

    // Applications techniques à ne jamais montrer (nom du .desktop sans « .desktop »)
    readonly property var masquees: [
        "avahi-discover", "bssh", "bvnc", "qv4l2", "qvidcap", "xgps", "xgpsspeed",
        "rofi", "rofi-theme-selector", "thunar-bulk-rename", "thunar-settings",
        "thunar-volman-settings", "vim", "nvim", "lstopo", "cmake-gui",
        "org.freedesktop.IBus.Setup", "electron", "jconsole", "jshell", "uxterm", "xterm",
        "mpv"   // remplacé par « Lecteur NexusOS »
    ]

    function visible(appli) {
        return appli && !appli.noDisplay && masquees.indexOf(appli.id) < 0;
    }

    // Lance une commande sans attendre
    function lancer(commande) { Quickshell.execDetached(commande); }

    // Ouvre une application et ferme le menu
    function ouvrir(appli) {
        appli.execute();
        menuOuvert = false;
    }

    // Palette NexusOS
    readonly property color cFond:    Qt.rgba(6/255, 12/255, 34/255, 0.86)
    readonly property color cBord:    Qt.rgba(79/255, 139/255, 255/255, 0.75)
    readonly property color cSurvol:  Qt.rgba(79/255, 139/255, 255/255, 0.22)
    readonly property color cCase:    Qt.rgba(1, 1, 1, 0.05)
    readonly property color cLigne:   Qt.rgba(154/255, 168/255, 214/255, 0.25)
    readonly property color cAccent:  "#4f8bff"
    readonly property color cAccent2: "#2f6bff"
    readonly property color cViolet:  "#8b5cf6"
    readonly property color cTexte:   "#e6ecff"
    readonly property color cDiscret: "#9aa8d6"
    readonly property string police:  "Noto Sans"
    readonly property string icones:  "JetBrainsMono Nerd Font"
}
