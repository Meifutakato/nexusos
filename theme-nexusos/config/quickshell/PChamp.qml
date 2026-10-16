// Paramètres NexusOS — champ de texte arrondi
import QtQuick

Rectangle {
    id: champ
    property alias texte: saisie.text
    property string indication: ""
    property bool motDePasse: false
    signal valide(string texte)
    implicitWidth: 240
    implicitHeight: 36
    radius: 18
    color: Qt.rgba(1, 1, 1, 0.06)
    border.width: 1
    border.color: saisie.activeFocus ? Etat.cBord : Qt.rgba(154/255, 168/255, 214/255, 0.25)
    function focaliser() { saisie.forceActiveFocus(); }

    TextInput {
        id: saisie
        anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
        verticalAlignment: TextInput.AlignVCenter
        echoMode: champ.motDePasse ? TextInput.Password : TextInput.Normal
        font.family: Etat.police
        font.pixelSize: 13
        color: Etat.cTexte
        selectionColor: Etat.cAccent2
        clip: true
        Keys.onReturnPressed: champ.valide(text)
        Keys.onEnterPressed: champ.valide(text)
        Text {
            visible: saisie.text === ""
            anchors.verticalCenter: parent.verticalCenter
            text: champ.indication
            font: saisie.font
            color: Etat.cDiscret
        }
    }
}
