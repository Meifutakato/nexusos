pragma Singleton
// NexusOS — état partagé entre la barre et le menu Démarrer
import Quickshell
import QtQuick

Singleton {
    id: etat

    property bool menuOuvert: false
    function basculerMenu() { menuOuvert = !menuOuvert; }

    // Applications techniques à ne jamais montrer (nom du .desktop sans « .desktop »)
    readonly property var masquees: [
        "avahi-discover", "bssh", "bvnc", "qv4l2", "qvidcap", "xgps", "xgpsspeed",
        "rofi", "rofi-theme-selector", "thunar-bulk-rename", "thunar-settings",
        "thunar-volman-settings", "vim", "nvim", "lstopo", "cmake-gui",
        "org.freedesktop.IBus.Setup", "electron", "jconsole", "jshell", "uxterm", "xterm"
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
