// NexusOS — poignée de fenêtre façon HyperOS
// Trois points en haut au centre de la fenêtre active. Un clic ouvre une pastille :
//   plein écran · moitié gauche · moitié droite · petite fenêtre flottante · fermer
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

PanelWindow {
    id: poignee

    // ── Fenêtre active (informations de Hyprland) ───────────────
    property var active: Hyprland.activeToplevel
    property var infos: active ? active.lastIpcObject : null
    property bool ouverte: false

    readonly property bool valide: infos !== null && infos !== undefined
                                   && infos.at !== undefined && infos.size !== undefined
                                   && String(infos.workspace ? infos.workspace.name : "").indexOf("special") !== 0
    readonly property int pleinEcran: valide && infos.fullscreen ? Number(infos.fullscreen) : 0
    readonly property bool flottante: valide && infos.floating === true

    // Position de la fenêtre sur cet écran
    readonly property real fx: valide ? infos.at[0] - (screen ? screen.x : 0) : 0
    readonly property real fy: valide ? infos.at[1] - (screen ? screen.y : 0) : 0
    readonly property real fl: valide ? infos.size[0] : 0
    readonly property real fh: valide ? infos.size[1] : 0

    // Zone de travail (entre la barre du haut et celle du bas)
    readonly property int ecranL: screen ? screen.width : 1920
    readonly property int ecranH: screen ? screen.height : 1080
    readonly property int hautLibre: 66
    readonly property int basLibre: 92
    readonly property int marge: 14

    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    visible: valide && pleinEcran < 2 && !Etat.menuOuvert
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "nexus-poignee"
    anchors { top: true; left: true }
    implicitWidth: 340
    implicitHeight: 96
    margins {
        left: Math.max(0, Math.round(poignee.fx + poignee.fl / 2 - poignee.implicitWidth / 2))
        // dans l'espace libre au-dessus de la fenêtre (ne cache pas son contenu) ;
        // s'il n'y a pas la place (fenêtre agrandie), juste à l'intérieur du bord
        top: Math.max(0, Math.round(poignee.fy >= 70 ? poignee.fy - 16 : poignee.fy + 1))
    }

    // Seules les zones visibles reçoivent les clics (le reste passe à la fenêtre dessous)
    mask: Region { item: zoneCliquable }

    // Mise à jour de la position (Hyprland ne signale pas tous les déplacements)
    Timer {
        interval: 1000; repeat: true
        running: Hyprland.activeToplevel !== null && !Etat.menuOuvert
        onTriggered: Hyprland.refreshToplevels()
    }
    Connections {
        target: Hyprland
        function onRawEvent(evenement) { Hyprland.refreshToplevels(); }
    }
    onActiveChanged: ouverte = false

    // Ferme la pastille si on ne s'en sert pas
    Timer {
        id: fermetureAuto
        interval: 5000
        running: poignee.ouverte && !survolPastille.hovered
        onTriggered: poignee.ouverte = false
    }

    // ── Actions ─────────────────────────────────────────────────
    function adresse() {
        let a = String(infos.address || (active ? active.address : ""));
        if (a.indexOf("0x") !== 0) a = "0x" + a;
        return "address:" + a;
    }
    function d(commande) { Hyprland.dispatch(commande); }

    function placer(x, y, l, h) {
        const a = adresse();
        if (pleinEcran > 0) d("fullscreen 1");
        if (!flottante) d("setfloating " + a);
        d("resizewindowpixel exact " + Math.round(l) + " " + Math.round(h) + "," + a);
        d("movewindowpixel exact " + Math.round(x + (screen ? screen.x : 0)) + " " + Math.round(y + (screen ? screen.y : 0)) + "," + a);
    }

    function agrandir() {
        if (flottante) d("settiled " + adresse());
        else d("fullscreen 1");
    }
    function moitie(gauche) {
        const l = ecranL / 2 - marge * 1.5;
        const h = ecranH - hautLibre - basLibre;
        placer(gauche ? marge : ecranL / 2 + marge / 2, hautLibre, l, h);
    }
    function petite() {
        placer(ecranL * 0.225, ecranH * 0.18, ecranL * 0.55, ecranH * 0.6);
    }
    function fermer() { d("closewindow " + adresse()); }

    // Mode actuel, pour allumer le bon bouton
    readonly property int mode: {
        if (!valide) return 0;
        if (!flottante) return 1;
        if (Math.abs(fx - marge) < 20 && Math.abs(fl - (ecranL / 2 - marge * 1.5)) < 30) return 2;
        if (Math.abs(fx - (ecranL / 2 + marge / 2)) < 20) return 3;
        return 4;
    }

    // ── Dessin ──────────────────────────────────────────────────
    Item {
        id: zoneCliquable
        x: poignee.ouverte ? pastille.x : points.x - 3
        y: points.y - 3
        width: poignee.ouverte ? pastille.width : points.width + 6
        height: poignee.ouverte ? pastille.y + pastille.height - points.y + 3 : points.height + 6
    }

    // Les trois points
    Rectangle {
        id: points
        anchors { top: parent.top; topMargin: 3; horizontalCenter: parent.horizontalCenter }
        width: 40; height: 12; radius: 6
        color: zonePoints.containsMouse || poignee.ouverte ? Qt.rgba(79/255, 139/255, 1, 0.35) : Qt.rgba(0, 0, 0, 0.18)
        Behavior on color { ColorAnimation { duration: 120 } }
        Row {
            anchors.centerIn: parent
            spacing: 4
            Repeater {
                model: 3
                Rectangle {
                    width: 5; height: 5; radius: 2.5
                    color: zonePoints.containsMouse || poignee.ouverte ? "#d7dbe3" : "#9ba1ab"
                }
            }
        }
        MouseArea {
            id: zonePoints
            anchors.fill: parent
            anchors.margins: -3
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: poignee.ouverte = !poignee.ouverte
        }
    }

    // La pastille d'actions
    Rectangle {
        id: pastille
        visible: opacity > 0
        opacity: poignee.ouverte ? 1 : 0
        scale: poignee.ouverte ? 1 : 0.92
        Behavior on opacity { NumberAnimation { duration: 140 } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
        anchors { top: points.bottom; topMargin: 8; horizontalCenter: parent.horizontalCenter }
        width: rangee.implicitWidth + 20
        height: 64
        radius: 32
        color: Qt.rgba(34/255, 36/255, 42/255, 0.96)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.06)

        HoverHandler { id: survolPastille }

        Row {
            id: rangee
            anchors.centerIn: parent
            spacing: 6

            Repeater {
                model: [
                    { n: 1, titre: "Plein écran" },
                    { n: 2, titre: "Moitié gauche" },
                    { n: 3, titre: "Moitié droite" },
                    { n: 4, titre: "Petite fenêtre" },
                    { n: 5, titre: "Fermer" }
                ]
                Rectangle {
                    id: bouton
                    required property var modelData
                    property bool actif: poignee.mode === modelData.n
                    width: 54; height: 48; radius: 24
                    color: actif ? Qt.rgba(47/255, 107/255, 1, 0.16)
                         : (zoneBouton.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : "transparent")
                    Behavior on color { ColorAnimation { duration: 110 } }

                    // Cadre de l'icône
                    Rectangle {
                        id: cadre
                        anchors.centerIn: parent
                        width: 26; height: 26; radius: 6
                        color: bouton.modelData.n === 1 && bouton.actif ? "#2f6bff" : "transparent"
                        border.width: 2.5
                        border.color: bouton.actif ? "#5b8cff" : "#8a8f98"

                        // 2 : moitié gauche pleine
                        Rectangle {
                            visible: bouton.modelData.n === 2 || bouton.modelData.n === 3
                            x: bouton.modelData.n === 2 ? 4 : parent.width / 2 + 1
                            y: 4
                            width: parent.width / 2 - 5
                            height: parent.height - 8
                            radius: 2
                            color: bouton.actif ? "#5b8cff" : "#d9dce2"
                        }
                        Rectangle {
                            visible: bouton.modelData.n === 2 || bouton.modelData.n === 3
                            x: bouton.modelData.n === 2 ? parent.width / 2 + 1 : 4
                            y: 4
                            width: parent.width / 2 - 5
                            height: parent.height - 8
                            radius: 2
                            color: "#5d626b"
                        }
                        // 4 : petite fenêtre
                        Rectangle {
                            visible: bouton.modelData.n === 4
                            x: parent.width - width - 5; y: 5
                            width: 9; height: 12; radius: 2
                            color: bouton.actif ? "#5b8cff" : "#d9dce2"
                        }
                        // 5 : croix
                        Text {
                            visible: bouton.modelData.n === 5
                            anchors.centerIn: parent
                            text: "✕"
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            color: zoneBouton.containsMouse ? "#ff6b6b" : "#e6e8ec"
                        }
                    }

                    MouseArea {
                        id: zoneBouton
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const n = bouton.modelData.n;
                            poignee.ouverte = false;
                            if (n === 1) poignee.agrandir();
                            else if (n === 2) poignee.moitie(true);
                            else if (n === 3) poignee.moitie(false);
                            else if (n === 4) poignee.petite();
                            else poignee.fermer();
                        }
                    }
                }
            }
        }
    }
}
