// Paramètres NexusOS — pastille de couleur avec un pictogramme (police Nerd Font)
import QtQuick

Rectangle {
    id: pastille
    property string glyphe: ""
    property color teinte: Etat.cAccent2
    property int taille: 30
    width: taille; height: taille
    radius: taille * 0.3
    gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.lighter(pastille.teinte, 1.25) }
        GradientStop { position: 1.0; color: pastille.teinte }
    }
    Text {
        anchors.centerIn: parent
        text: pastille.glyphe
        font.family: Etat.icones
        font.pixelSize: pastille.taille * 0.52
        color: "white"
    }
}
