// Paramètres NexusOS — bouton arrondi (plein = action principale)
import QtQuick

Rectangle {
    id: bouton
    property string texte: ""
    property bool plein: false
    property bool danger: false
    property bool actif: true
    signal clique()
    implicitWidth: libelle.implicitWidth + 32
    implicitHeight: 34
    radius: 10
    opacity: actif ? 1 : 0.5
    color: plein ? (zone.containsMouse ? "#4f8bff" : "#2f6bff")
                 : (zone.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.07))
    border.width: plein ? 0 : 1
    border.color: danger ? Qt.rgba(1, 0.42, 0.42, 0.6) : Qt.rgba(154/255, 168/255, 214/255, 0.30)
    Behavior on color { ColorAnimation { duration: 110 } }
    Text {
        id: libelle
        anchors.centerIn: parent
        text: bouton.texte
        font.family: Etat.police
        font.pixelSize: 13
        color: bouton.danger ? "#ff8a8a" : Etat.cTexte
    }
    MouseArea {
        id: zone
        anchors.fill: parent
        enabled: bouton.actif
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: bouton.clique()
    }
}
