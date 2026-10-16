// Paramètres NexusOS — une ligne de réglage : pictogramme, titre, détail, et un élément à droite
import QtQuick
import QtQuick.Layouts

Item {
    id: ligne
    property string glyphe: ""
    property color teinte: Etat.cAccent2
    property string titre: ""
    property string detail: ""
    property string valeur: ""          // texte gris à droite (ex. « Activé »)
    property bool fleche: false          // chevron › à droite
    property bool cliquable: fleche
    property bool separateur: true
    default property alias droite: zoneDroite.data
    signal clique()

    Layout.fillWidth: true
    implicitHeight: Math.max(60, textes.implicitHeight + 24)

    Rectangle {
        anchors { fill: parent; leftMargin: 6; rightMargin: 6; topMargin: 2; bottomMargin: 2 }
        radius: 12
        color: ligne.cliquable && zone.containsMouse ? Qt.rgba(79/255, 139/255, 1, 0.12) : "transparent"
        Behavior on color { ColorAnimation { duration: 110 } }
    }
    MouseArea {
        id: zone
        anchors.fill: parent
        enabled: ligne.cliquable
        hoverEnabled: true
        cursorShape: ligne.cliquable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: ligne.clique()
    }

    RowLayout {
        anchors { fill: parent; leftMargin: 20; rightMargin: 18 }
        spacing: 14

        PIcone {
            visible: ligne.glyphe !== ""
            glyphe: ligne.glyphe
            teinte: ligne.teinte
            taille: 32
        }
        Column {
            id: textes
            Layout.fillWidth: true
            spacing: 2
            Text {
                width: parent.width
                text: ligne.titre
                elide: Text.ElideRight
                font.family: Etat.police
                font.pixelSize: 14
                font.weight: Font.DemiBold
                color: Etat.cTexte
            }
            Text {
                visible: ligne.detail !== ""
                width: parent.width
                text: ligne.detail
                wrapMode: Text.WordWrap
                font.family: Etat.police
                font.pixelSize: 12
                color: Etat.cDiscret
            }
        }
        Text {
            visible: ligne.valeur !== ""
            text: ligne.valeur
            font.family: Etat.police
            font.pixelSize: 13
            color: Etat.cDiscret
        }
        Row {
            id: zoneDroite
            spacing: 10
            Layout.alignment: Qt.AlignVCenter
        }
        Text {
            visible: ligne.fleche
            text: ""
            font.family: Etat.icones
            font.pixelSize: 12
            color: Etat.cDiscret
        }
    }

    Rectangle {
        visible: ligne.separateur
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 66; rightMargin: 18 }
        height: 1
        color: Qt.rgba(154/255, 168/255, 214/255, 0.10)
    }
}
