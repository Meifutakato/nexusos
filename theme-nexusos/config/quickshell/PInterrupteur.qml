// Paramètres NexusOS — interrupteur marche / arrêt
import QtQuick

Item {
    id: inter
    property bool coche: false
    property bool actif: true            // false = grisé (en attente)
    signal bascule(bool valeur)
    width: 46; height: 26
    opacity: actif ? 1 : 0.5

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: inter.coche ? "transparent" : Qt.rgba(154/255, 168/255, 214/255, 0.30)
        gradient: inter.coche ? degrade : null
        Gradient {
            id: degrade
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#2f6bff" }
            GradientStop { position: 1.0; color: "#8b5cf6" }
        }
    }
    Rectangle {
        width: 20; height: 20; radius: 10
        y: 3
        x: inter.coche ? parent.width - width - 3 : 3
        color: "white"
        Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }
    MouseArea {
        anchors.fill: parent
        enabled: inter.actif
        cursorShape: Qt.PointingHandCursor
        onClicked: inter.bascule(!inter.coche)
    }
}
