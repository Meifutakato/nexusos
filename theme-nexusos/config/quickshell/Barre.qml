// NexusOS — barre du bas : bouton menu, recherche, applications, heure
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: barre
    required property var modelData
    screen: modelData

    // ── Réglages faciles à modifier ─────────────────────────────
    // Applications épinglées : nom du fichier .desktop, sans « .desktop ».
    // Celles qui ne sont pas installées sont simplement ignorées.
    property var epingles: [
        "thunar", "firefox", "microsoft-edge",
        "onlyoffice-desktopeditors",
        "libreoffice-writer", "libreoffice-calc", "libreoffice-impress",
        "kitty", "discord", "steam", "spotify",
        "com.heroicgameslauncher.hgl", "org.pulseaudio.pavucontrol"
    ]

    // Palette NexusOS
    readonly property color cFond:    Qt.rgba(6/255, 12/255, 34/255, 0.78)
    readonly property color cBord:    Qt.rgba(79/255, 139/255, 255/255, 0.75)
    readonly property color cSurvol:  Qt.rgba(79/255, 139/255, 255/255, 0.22)
    readonly property color cAccent:  "#4f8bff"
    readonly property color cTexte:   "#e6ecff"
    readonly property color cDiscret: "#9aa8d6"

    // ── Fenêtre de la barre ─────────────────────────────────────
    WlrLayershell.namespace: "nexus-barre"
    WlrLayershell.layer: WlrLayer.Top
    anchors { bottom: true; left: true; right: true }
    margins {
        bottom: 12
        left: Math.round(barre.screen.width * 0.08)
        right: Math.round(barre.screen.width * 0.08)
    }
    implicitHeight: 66
    color: "transparent"

    // ── Outils ──────────────────────────────────────────────────
    function ouvrirMenu() { Etat.basculerMenu(); }

    function minuscule(t) { return t ? String(t).toLowerCase() : ""; }

    // Retrouve la fenêtre ouverte d'une application (ou null)
    function fenetreDe(appli) {
        const fenetres = ToplevelManager.toplevels.values;
        const id = minuscule(appli.id);
        const court = id.split(".").pop();
        const nom = minuscule(appli.name);
        for (let i = 0; i < fenetres.length; i++) {
            const a = minuscule(fenetres[i].appId);
            if (a === id || a === court || a === nom || a.split(".").pop() === court)
                return fenetres[i];
        }
        return null;
    }

    // Affiche une fenêtre ; si elle a été réduite (bouton jaune en haut),
    // elle est ramenée sur le bureau actuel
    function montrer(fenetre) {
        const liste = Hyprland.toplevels ? Hyprland.toplevels.values : [];
        for (let i = 0; i < liste.length; i++) {
            const h = liste[i];
            if (h.wayland === fenetre && h.workspace && String(h.workspace.name).indexOf("special") === 0) {
                let adresse = String(h.address);
                if (adresse.indexOf("0x") !== 0) adresse = "0x" + adresse;
                Hyprland.dispatch("movetoworkspace " + Hyprland.focusedWorkspace.id + ",address:" + adresse);
                return;
            }
        }
        fenetre.activate();
    }

    // Applications affichées : les épinglées, puis les autres fenêtres ouvertes
    property var applis: {
        DesktopEntries.applications.values;          // se met à jour quand la liste est prête
        const liste = [];
        const vus = {};
        for (let i = 0; i < epingles.length; i++) {
            const e = DesktopEntries.byId(epingles[i]);
            if (e && !vus[e.id]) { liste.push(e); vus[e.id] = true; }
        }
        if (typeof DesktopEntries.heuristicLookup === "function") {
            const fenetres = ToplevelManager.toplevels.values;
            for (let i = 0; i < fenetres.length; i++) {
                const e = DesktopEntries.heuristicLookup(fenetres[i].appId);
                if (e && !vus[e.id]) { liste.push(e); vus[e.id] = true; }
            }
        }
        return liste;
    }

    SystemClock { id: horloge; precision: SystemClock.Minutes }

    // ── Dessin ──────────────────────────────────────────────────
    Rectangle {
        id: fond
        anchors.fill: parent
        radius: height / 2
        color: barre.cFond
        border.width: 1
        border.color: barre.cBord

        // reflet léger en haut, effet verre
        Rectangle {
            anchors { fill: parent; margins: 1 }
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.07) }
                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.0) }
            }
        }

        RowLayout {
            anchors { fill: parent; leftMargin: 12; rightMargin: 24 }
            spacing: 14

            // Bouton menu : logo NexusOS
            Rectangle {
                id: boutonMenu
                Layout.preferredWidth: 46
                Layout.preferredHeight: 46
                radius: 14
                color: zoneMenu.containsMouse ? barre.cSurvol : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }

                Image {
                    anchors.centerIn: parent
                    width: 36; height: 36
                    sourceSize: Qt.size(72, 72)
                    source: Etat.logo
                    smooth: true
                    scale: zoneMenu.pressed ? 0.88 : (zoneMenu.containsMouse ? 1.08 : 1)
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
                }
                MouseArea {
                    id: zoneMenu
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: barre.ouvrirMenu()
                }
            }

            // Champ « Rechercher »
            Rectangle {
                Layout.preferredWidth: 230
                Layout.preferredHeight: 40
                radius: 20
                color: zoneRecherche.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.05)
                border.width: 1
                border.color: Qt.rgba(154/255, 168/255, 214/255, 0.25)
                Behavior on color { ColorAnimation { duration: 120 } }

                Row {
                    anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 16 }
                    spacing: 10
                    Text {
                        text: ""                       // loupe (police Nerd Font)
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                        color: barre.cDiscret
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "Rechercher"
                        font.family: "Noto Sans"
                        font.pixelSize: 14
                        color: barre.cDiscret
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                MouseArea {
                    id: zoneRecherche
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.IBeamCursor
                    onClicked: barre.ouvrirMenu()
                }
            }

            // Séparateur
            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 30
                color: Qt.rgba(154/255, 168/255, 214/255, 0.35)
            }

            // Applications
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Row {
                    anchors.centerIn: parent
                    spacing: 6

                    Repeater {
                        model: barre.applis

                        Item {
                            id: icone
                            required property var modelData
                            property var fenetre: barre.fenetreDe(modelData)
                            width: 52; height: 52

                            Rectangle {
                                anchors.fill: parent
                                radius: 14
                                color: zone.containsMouse ? barre.cSurvol
                                     : (icone.fenetre && icone.fenetre.activated ? Qt.rgba(79/255, 139/255, 1, 0.12) : "transparent")
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }

                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: 36
                                source: Quickshell.iconPath(icone.modelData.icon, "application-x-executable")
                                scale: zone.pressed ? 0.9 : (zone.containsMouse ? 1.12 : 1)
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                            }

                            // Trait sous les applications ouvertes (plus long si active)
                            Rectangle {
                                visible: icone.fenetre !== null
                                anchors { bottom: parent.bottom; bottomMargin: 1; horizontalCenter: parent.horizontalCenter }
                                width: icone.fenetre && icone.fenetre.activated ? 18 : 6
                                height: 3
                                radius: 2
                                color: barre.cAccent
                                Behavior on width { NumberAnimation { duration: 150 } }
                            }

                            MouseArea {
                                id: zone
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (icone.fenetre) barre.montrer(icone.fenetre);
                                    else icone.modelData.execute();
                                }
                            }
                        }
                    }
                }
            }

            // Date et heure
            Row {
                spacing: 12
                Text {
                    property string jour: horloge.date.toLocaleDateString(Qt.locale("fr_FR"), "ddd d MMM")
                    text: jour.charAt(0).toUpperCase() + jour.slice(1)
                    font.family: "Noto Sans"
                    font.pixelSize: 14
                    color: barre.cTexte
                }
                Text {
                    text: Qt.formatTime(horloge.date, "HH:mm")
                    font.family: "Noto Sans"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: barre.cTexte
                }
            }
        }
    }
}
