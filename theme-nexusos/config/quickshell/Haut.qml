// NexusOS — barre du haut : bureaux à gauche,
// îlot d'état au centre (réseau, Bluetooth, USB, volume, batterie).
// La date et l'heure sont dans la barre du bas.
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: haut
    required property var modelData
    screen: modelData

    WlrLayershell.namespace: "nexus-haut"
    WlrLayershell.layer: WlrLayer.Top
    anchors { top: true; left: true; right: true }
    margins { top: 8; left: 14; right: 14 }
    implicitHeight: 50
    color: "transparent"

    // ── État du système (rempli par etat.sh) ────────────────────
    property string typeReseau: "aucun"     // wifi / ethernet / aucun
    property string etatReseau: "connexion" // connecte / connexion / deconnecte
    property string nomReseau: ""
    property int batterie: -1               // -1 : pas de batterie
    property bool enCharge: false
    property string bluetooth: "absent"     // absent / off / on
    property int usb: 0
    property int volume: -1
    property bool muet: false

    function lire(ligne) {
        const champs = ligne.split("\t");
        const v = {};
        for (let i = 0; i < champs.length; i++) {
            const p = champs[i].indexOf("=");
            if (p > 0) v[champs[i].substring(0, p)] = champs[i].substring(p + 1);
        }
        typeReseau = v.reseau || "aucun";
        etatReseau = v.etat || "deconnecte";
        nomReseau = v.nom || "";
        batterie = v.bat ? parseInt(v.bat) : -1;
        enCharge = (v.charge || "").indexOf("Charging") === 0 || v.charge === "Full";
        bluetooth = v.bt || "absent";
        usb = parseInt(v.usb || "0");
        const m = /([0-9.]+)/.exec(v.vol || "");
        volume = m ? Math.round(parseFloat(m[1]) * 100) : -1;
        muet = (v.vol || "").indexOf("MUTED") >= 0;
    }

    Process {
        id: sonde
        command: ["sh", Quickshell.env("HOME") + "/.config/quickshell/etat.sh"]
        running: true
        stdout: SplitParser { onRead: data => haut.lire(data) }
    }
    Timer {
        interval: 5000; running: true; repeat: true
        onTriggered: sonde.running = true
    }
    function rafraichir() { sonde.running = true; }


    // Glyphes (police Nerd Font)
    readonly property string gEthernet: String.fromCodePoint(0xF0200)
    function glypheBatterie() {
        if (enCharge) return "";
        if (batterie >= 85) return "";
        if (batterie >= 60) return "";
        if (batterie >= 35) return "";
        if (batterie >= 12) return "";
        return "";
    }
    function glypheVolume() {
        if (muet || volume === 0) return "";
        return volume < 50 ? "" : "";
    }

    // Icône de l'îlot
    component IconeIlot: Text {
        font.family: Etat.icones
        font.pixelSize: 16
        color: Etat.cTexte
        Layout.alignment: Qt.AlignVCenter
    }

    // ── Gauche : bureaux ────────────────────────────────────────
    Row {
        anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
        spacing: 9



        Repeater {
            model: 4
            Rectangle {
                required property int index
                property bool actif: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === index + 1
                anchors.verticalCenter: parent.verticalCenter
                width: actif ? 22 : 8
                height: 8
                radius: 4
                color: actif ? Etat.cAccent : (zoneBureau.containsMouse ? Etat.cTexte : Qt.rgba(154/255, 168/255, 214/255, 0.5))
                Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                MouseArea {
                    id: zoneBureau
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("workspace " + (index + 1))
                }
            }
        }
    }

    // ── Centre : l'îlot ─────────────────────────────────────────
    Rectangle {
        id: ilot
        anchors.centerIn: parent
        height: 48
        width: contenuIlot.implicitWidth + 36
        radius: 24
        color: Etat.cFond
        border.width: 1
        border.color: Etat.cBord
        Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors { fill: parent; margins: 1 }
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.07) }
                GradientStop { position: 0.6; color: Qt.rgba(1, 1, 1, 0.0) }
            }
        }

        RowLayout {
            id: contenuIlot
            anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 14 }
            spacing: 14

            // Anneau : tourne pendant la connexion, plein une fois connecté
            Canvas {
                id: anneau
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                property real angle: 0
                onAngleChanged: requestPaint()
                onPaint: {
                    const c = getContext("2d");
                    c.reset();
                    c.lineWidth = 4;
                    c.lineCap = "round";
                    const r = width / 2 - 3;
                    if (haut.etatReseau === "deconnecte") {
                        c.strokeStyle = "rgba(154,168,214,0.45)";
                    } else {
                        const g = c.createLinearGradient(0, 0, width, height);
                        g.addColorStop(0, "#4f8bff");
                        g.addColorStop(1, "#8b5cf6");
                        c.strokeStyle = g;
                    }
                    c.beginPath();
                    if (haut.etatReseau === "connexion")
                        c.arc(width / 2, height / 2, r, angle, angle + Math.PI * 1.4);
                    else
                        c.arc(width / 2, height / 2, r, 0, Math.PI * 2);
                    c.stroke();
                }
                NumberAnimation on angle {
                    from: 0; to: Math.PI * 2
                    duration: 1100
                    loops: Animation.Infinite
                    running: haut.etatReseau === "connexion"
                }
                Connections {
                    target: haut
                    function onEtatReseauChanged() { anneau.requestPaint(); }
                }
            }

            // Texte : état + nom du réseau
            Item {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: textesReseau.implicitWidth
                implicitHeight: textesReseau.implicitHeight
                Column {
                    id: textesReseau
                    Text {
                        text: haut.etatReseau === "connecte" ? "Connecté"
                            : (haut.etatReseau === "connexion" ? "Connexion en cours…" : "Hors ligne")
                        font.family: Etat.police
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: Etat.cTexte
                    }
                    Text {
                        text: haut.typeReseau === "wifi" ? "Wi-Fi" + (haut.nomReseau ? " · " + haut.nomReseau : "")
                            : (haut.typeReseau === "ethernet" ? "Ethernet" + (haut.nomReseau ? " · " + haut.nomReseau : "")
                            : "Aucun réseau")
                        font.family: Etat.police
                        font.pixelSize: 10
                        color: Etat.cDiscret
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Etat.lancer(["sh", "-c", "command -v nm-connection-editor >/dev/null && exec nm-connection-editor || exec kitty -e nmtui"])
                }
            }

            Item { Layout.preferredWidth: 6 }

            // Réseau
            IconeIlot {
                text: haut.typeReseau === "ethernet" ? haut.gEthernet : ""
                color: haut.etatReseau === "connecte" ? Etat.cTexte : Etat.cDiscret
            }
            // Bluetooth
            IconeIlot {
                visible: haut.bluetooth !== "absent"
                text: ""
                color: haut.bluetooth === "on" ? Etat.cTexte : Etat.cDiscret
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Etat.lancer(["sh", "-c", "command -v blueman-manager >/dev/null && exec blueman-manager || exec kitty -e bluetoothctl"])
                }
            }
            // Clé USB branchée
            IconeIlot {
                visible: haut.usb > 0
                text: ""
            }
            // Volume : clic = réglages du son, molette = monter / baisser
            Item {
                visible: haut.volume >= 0
                implicitWidth: ligneVolume.implicitWidth
                implicitHeight: ligneVolume.implicitHeight
                RowLayout {
                    id: ligneVolume
                    anchors.fill: parent
                    spacing: 6
                    IconeIlot { text: haut.glypheVolume() }
                    Text {
                        text: haut.muet ? "Muet" : haut.volume + "%"
                        font.family: Etat.police
                        font.pixelSize: 12
                        color: Etat.cTexte
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Etat.lancer(["pavucontrol"])
                }
            }
            // Batterie
            RowLayout {
                visible: haut.batterie >= 0
                spacing: 6
                IconeIlot {
                    text: haut.glypheBatterie()
                    color: haut.batterie < 15 && !haut.enCharge ? "#ff5f57" : Etat.cTexte
                }
                Text {
                    text: haut.batterie + "%"
                    font.family: Etat.police
                    font.pixelSize: 12
                    color: Etat.cTexte
                }
            }
        }

        // Zone du volume (molette partout sur la droite de l'îlot)
        MouseArea {
            anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
            width: parent.width / 2
            acceptedButtons: Qt.MiddleButton
            onWheel: wheel => {
                Etat.lancer(["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", wheel.angleDelta.y > 0 ? "5%+" : "5%-"]);
                haut.rafraichir();
            }
            onClicked: Etat.lancer(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
        }
    }
}
