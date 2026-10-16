// Paramètres NexusOS — carte arrondie qui regroupe des lignes
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: carte
    default property alias contenu: colonne.data
    property string titre: ""
    Layout.fillWidth: true
    implicitHeight: colonne.implicitHeight + (titre !== "" ? 36 : 0) + 8
    radius: 16
    color: Qt.rgba(1, 1, 1, 0.04)
    border.width: 1
    border.color: Qt.rgba(154/255, 168/255, 214/255, 0.18)

    Text {
        visible: carte.titre !== ""
        x: 20; y: 14
        text: carte.titre
        font.family: Etat.police
        font.pixelSize: 12
        font.weight: Font.DemiBold
        color: Etat.cDiscret
    }
    ColumnLayout {
        id: colonne
        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: (carte.titre !== "" ? 36 : 4) }
        spacing: 0
    }
}
