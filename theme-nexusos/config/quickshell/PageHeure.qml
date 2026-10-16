// Paramètres › Heure et langue
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    spacing: 14

    PSource { id: h; sujet: "heure"; Component.onCompleted: recharger() }
    Connections { target: Etat; function onActionParamTerminee() { h.recharger(); } }
    property var d: h.donnees || ({})
    SystemClock { id: horloge; precision: SystemClock.Seconds }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 110
        radius: 18
        color: Qt.rgba(1, 1, 1, 0.04)
        border.width: 1
        border.color: Qt.rgba(154/255, 168/255, 214/255, 0.18)
        Column {
            anchors { left: parent.left; leftMargin: 24; verticalCenter: parent.verticalCenter }
            Text {
                text: Qt.formatTime(horloge.date, "HH:mm:ss")
                font.family: Etat.police; font.pixelSize: 40; font.weight: Font.Light; color: Etat.cTexte
            }
            Text {
                property string j: horloge.date.toLocaleDateString(Qt.locale("fr_FR"), "dddd d MMMM yyyy")
                text: j.charAt(0).toUpperCase() + j.slice(1)
                font.family: Etat.police; font.pixelSize: 14; color: Etat.cDiscret
            }
        }
    }

    PCarte {
        titre: "Heure"
        PLigne {
            glyphe: ""; teinte: "#14b8a6"
            titre: "Régler l'heure automatiquement"
            detail: page.d.ntp ? (page.d.synchro ? "Activé · synchronisée avec Internet" : "Activé · synchronisation en cours") : "Désactivé"
            PInterrupteur {
                anchors.verticalCenter: parent.verticalCenter
                coche: !!page.d.ntp
                onBascule: v => Etat.agirParam(["ntp", v ? "on" : "off"])
            }
        }
        PLigne {
            glyphe: ""; teinte: "#0ea5e9"
            titre: "Fuseau horaire"
            valeur: page.d.fuseau || "—"
            separateur: false
        }
    }

    PCarte {
        titre: "Langue"
        PLigne {
            glyphe: ""; teinte: "#8b5cf6"
            titre: "Langue du système"
            valeur: (page.d.langue || "").indexOf("fr") === 0 ? "Français" : (page.d.langue || "—")
        }
        PLigne {
            glyphe: ""; teinte: "#f59e0b"
            titre: "Clavier"
            valeur: page.d.clavier === "fr" ? "Français (AZERTY)" : (page.d.clavier || "—")
            separateur: false
        }
    }
}
