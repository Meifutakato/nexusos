// Paramètres › Batterie
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    spacing: 14

    PSource { id: b; sujet: "batterie"; Component.onCompleted: recharger() }
    Timer { interval: 30000; running: true; repeat: true; onTriggered: b.recharger() }
    property var d: b.donnees || ({})
    function etatFr(e) {
        return ({ "Charging": "En charge", "Discharging": "Sur batterie", "Full": "Chargée",
                  "Not charging": "Branchée, ne charge pas" })[e] || e || "—";
    }

    Rectangle {
        visible: !!page.d.presente
        Layout.fillWidth: true
        implicitHeight: 120
        radius: 18
        color: Qt.rgba(1, 1, 1, 0.04)
        border.width: 1
        border.color: Qt.rgba(154/255, 168/255, 214/255, 0.18)
        Row {
            anchors { left: parent.left; leftMargin: 24; verticalCenter: parent.verticalCenter }
            spacing: 22
            Text {
                text: (page.d.niveau || 0) + " %"
                font.family: Etat.police; font.pixelSize: 44; font.weight: Font.Light; color: Etat.cTexte
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                Rectangle {
                    width: 280; height: 14; radius: 7
                    color: Qt.rgba(154/255, 168/255, 214/255, 0.25)
                    Rectangle {
                        width: parent.width * (page.d.niveau || 0) / 100
                        height: parent.height; radius: 7
                        color: (page.d.niveau || 0) < 15 ? "#ef4444" : "#22c55e"
                    }
                }
                Text { text: page.etatFr(page.d.etat); font.family: Etat.police; font.pixelSize: 13; color: Etat.cDiscret }
            }
        }
    }

    PCarte {
        visible: page.d.presente === false
        PLigne {
            glyphe: ""; teinte: "#64748b"
            titre: "Pas de batterie"
            detail: "Ce PC est branché sur secteur"
            separateur: false
        }
    }

    PCarte {
        titre: "Économies d'énergie"
        PLigne {
            glyphe: ""; teinte: "#2f6bff"
            titre: "Mise en veille et écran"
            detail: "Délais de mise en veille — à venir"
            separateur: false
        }
    }
}
