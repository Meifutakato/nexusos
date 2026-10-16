// Paramètres › Fond d'écran et thème
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    spacing: 14

    PSource { id: f; sujet: "fonds"; Component.onCompleted: recharger() }
    Connections { target: Etat; function onActionParamTerminee() { f.recharger(); } }
    property var d: f.donnees || ({})

    PCarte {
        titre: "Fond d'écran"
        Flow {
            Layout.fillWidth: true
            Layout.margins: 16
            Layout.topMargin: 4
            spacing: 12
            Repeater {
                model: page.d.fonds || []
                Rectangle {
                    id: vignette
                    required property string modelData
                    property bool actuel: modelData === page.d.actuel
                    width: 192; height: 108
                    radius: 12
                    color: "#0b1433"
                    border.width: actuel ? 3 : 1
                    border.color: actuel ? Etat.cAccent : Qt.rgba(154/255, 168/255, 214/255, 0.25)
                    clip: true
                    Image {
                        anchors { fill: parent; margins: vignette.border.width }
                        source: "file://" + vignette.modelData
                        sourceSize: Qt.size(384, 216)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                    Rectangle {
                        visible: vignette.actuel
                        anchors { right: parent.right; top: parent.top; margins: 8 }
                        width: 24; height: 24; radius: 12
                        color: Etat.cAccent2
                        Text { anchors.centerIn: parent; text: ""; font.family: Etat.icones; font.pixelSize: 12; color: "white" }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Etat.agirParam(["fond", vignette.modelData])
                    }
                }
            }
        }
        Text {
            Layout.fillWidth: true
            Layout.leftMargin: 20; Layout.rightMargin: 20; Layout.bottomMargin: 14
            wrapMode: Text.WordWrap
            text: "Pour ajouter tes propres fonds : place des images dans ton dossier Images."
            font.family: Etat.police; font.pixelSize: 12; color: Etat.cDiscret
        }
    }

    PCarte {
        titre: "Thème"
        PLigne {
            glyphe: ""; teinte: "#2f6bff"
            titre: "Mode sombre"
            detail: "Le thème NexusOS est conçu en sombre (bleu nuit et violet)"
            PInterrupteur { anchors.verticalCenter: parent.verticalCenter; coche: true; actif: false }
        }
        PLigne {
            glyphe: ""; teinte: "#ec4899"
            titre: "Couleur d'accent et effets"
            detail: "Choix de la couleur et effets allégés — à venir"
            separateur: false
        }
    }
}
