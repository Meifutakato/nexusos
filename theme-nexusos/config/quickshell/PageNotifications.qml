// Paramètres › Notifications
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    spacing: 14

    PSource { id: n; sujet: "notifications"; Component.onCompleted: recharger() }
    Connections { target: Etat; function onActionParamTerminee() { n.recharger(); } }
    property var d: n.donnees || ({})

    PCarte {
        PLigne {
            glyphe: ""; teinte: "#ef4444"
            titre: "Ne pas déranger"
            detail: page.d.nePasDeranger ? "Activé — les notifications sont mises de côté" : "Désactivé"
            PInterrupteur {
                anchors.verticalCenter: parent.verticalCenter
                coche: !!page.d.nePasDeranger
                onBascule: v => Etat.agirParam(["nepasderanger", v ? "on" : "off"])
            }
        }
        PLigne {
            glyphe: ""; teinte: "#f59e0b"
            titre: "Historique"
            detail: (page.d.historique || 0) + " notification(s) gardée(s)"
            separateur: false
            PBouton {
                anchors.verticalCenter: parent.verticalCenter
                texte: "Tout effacer"
                onClique: Etat.agirParam(["effacer-notifs"])
            }
        }
    }
    PCarte {
        PLigne {
            glyphe: ""; teinte: "#8b5cf6"
            titre: "Tester"
            detail: "Afficher une notification d'exemple"
            fleche: true
            separateur: false
            onClique: Etat.lancer(["notify-send", "NexusOS", "Les notifications fonctionnent."])
        }
    }
}
