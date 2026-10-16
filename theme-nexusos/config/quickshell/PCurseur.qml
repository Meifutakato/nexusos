// Paramètres NexusOS — curseur (volume, micro…) ; envoie la valeur en continu et au relâchement
import QtQuick

Item {
    id: curseur
    property real valeur: 50
    property real maximum: 100
    property bool enDeplacement: zone.pressed
    signal change(real valeur)
    signal relache(real valeur)
    implicitWidth: 240
    height: 24

    property real affichee: enDeplacement ? valeurGlisse : valeur
    property real valeurGlisse: 0

    Rectangle {
        id: rail
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        height: 6; radius: 3
        color: Qt.rgba(154/255, 168/255, 214/255, 0.25)
        Rectangle {
            width: rail.width * Math.min(1, curseur.affichee / curseur.maximum)
            height: parent.height; radius: 3
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#4f8bff" }
                GradientStop { position: 1.0; color: "#8b5cf6" }
            }
        }
    }
    Rectangle {
        width: 18; height: 18; radius: 9
        anchors.verticalCenter: parent.verticalCenter
        x: rail.width * Math.min(1, curseur.affichee / curseur.maximum) - width / 2
        color: "#e6ecff"
        border.width: 4
        border.color: Qt.rgba(79/255, 139/255, 1, 0.45)
    }
    MouseArea {
        id: zone
        anchors.fill: parent
        anchors.margins: -6
        cursorShape: Qt.PointingHandCursor
        function calculer(x) {
            return Math.round(Math.max(0, Math.min(1, (x - 6) / rail.width)) * curseur.maximum);
        }
        onPressed: mouse => { curseur.valeurGlisse = calculer(mouse.x); curseur.change(curseur.valeurGlisse); }
        onPositionChanged: mouse => { if (pressed) { curseur.valeurGlisse = calculer(mouse.x); curseur.change(curseur.valeurGlisse); } }
        onReleased: mouse => { curseur.valeurGlisse = calculer(mouse.x); curseur.relache(curseur.valeurGlisse); }
    }
}
