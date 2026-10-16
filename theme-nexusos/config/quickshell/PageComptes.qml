// Paramètres › Comptes
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    spacing: 14

    PSource { id: infos; sujet: "infos"; Component.onCompleted: recharger() }
    property var d: infos.donnees || ({})
    property string utilisateur: String(Quickshell.env("USER") || "")

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 110
        radius: 18
        color: Qt.rgba(1, 1, 1, 0.04)
        border.width: 1
        border.color: Qt.rgba(154/255, 168/255, 214/255, 0.18)
        Row {
            anchors { left: parent.left; leftMargin: 22; verticalCenter: parent.verticalCenter }
            spacing: 18
            Rectangle {
                width: 72; height: 72; radius: 36
                clip: true
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#4f8bff" }
                    GradientStop { position: 1.0; color: "#8b5cf6" }
                }
                Text {
                    anchors.centerIn: parent
                    visible: photo.status !== Image.Ready
                    text: ""; font.family: Etat.icones; font.pixelSize: 30; color: "white"
                }
                Image {
                    id: photo
                    anchors.fill: parent
                    source: "file://" + Quickshell.env("HOME") + "/.face"
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                Text {
                    text: page.utilisateur.charAt(0).toUpperCase() + page.utilisateur.slice(1)
                    font.family: Etat.police; font.pixelSize: 20; font.weight: Font.DemiBold; color: Etat.cTexte
                }
                Text { text: "Compte local · administrateur"; font.family: Etat.police; font.pixelSize: 13; color: Etat.cDiscret }
            }
        }
    }

    PCarte {
        PLigne {
            glyphe: ""; teinte: "#f97316"
            titre: "Mot de passe"
            detail: "Changer le mot de passe de " + page.utilisateur
            fleche: true
            onClique: Etat.lancer(["kitty", "--title", "Mot de passe", "sh", "-c", "passwd; echo; read -p 'Appuie sur Entrée pour fermer' r"])
        }
        PLigne {
            glyphe: ""; teinte: "#ec4899"
            titre: "Photo du compte"
            detail: "Copie une image carrée dans ton dossier personnel sous le nom .face (affichée ici et dans le menu)"
            separateur: false
        }
    }
}
