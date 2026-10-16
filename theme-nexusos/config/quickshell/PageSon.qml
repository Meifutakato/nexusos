// Paramètres › Son : volume, sortie, micro
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    spacing: 14

    PSource { id: son; sujet: "son"; Component.onCompleted: recharger() }
    Connections { target: Etat; function onActionParamTerminee() { son.recharger(); } }
    property var d: son.donnees || ({})

    PCarte {
        titre: "Sortie"
        PLigne {
            glyphe: page.d.muet ? "" : ""; teinte: "#ec4899"
            titre: "Volume"
            detail: page.d.muet ? "Son coupé" : (page.d.volume >= 0 ? page.d.volume + " %" : "Aucune sortie audio")
            PCurseur {
                width: 280
                anchors.verticalCenter: parent.verticalCenter
                valeur: Math.max(0, page.d.volume || 0)
                onRelache: v => Etat.agirParam(["volume", String(v)])
            }
            PBouton {
                anchors.verticalCenter: parent.verticalCenter
                texte: page.d.muet ? "Rétablir" : "Couper"
                onClique: Etat.agirParam(["muet", "sortie"])
            }
        }
        Repeater {
            model: page.d.sorties || []
            PLigne {
                required property var modelData
                glyphe: ""; teinte: modelData.nom === page.d.sortieDefaut ? "#22c55e" : "#64748b"
                titre: modelData.description
                detail: modelData.nom === page.d.sortieDefaut ? "Sortie utilisée" : "Cliquer pour utiliser cette sortie"
                cliquable: modelData.nom !== page.d.sortieDefaut
                onClique: Etat.agirParam(["sortie", modelData.nom])
            }
        }
    }

    PCarte {
        titre: "Micro"
        PLigne {
            glyphe: ""; teinte: "#14b8a6"
            titre: "Volume du micro"
            detail: page.d.micro >= 0 ? (page.d.microMuet ? "Micro coupé" : page.d.micro + " %") : "Aucun micro détecté"
            PCurseur {
                visible: page.d.micro >= 0
                width: 280
                anchors.verticalCenter: parent.verticalCenter
                valeur: Math.max(0, page.d.micro || 0)
                onRelache: v => Etat.agirParam(["micro", String(v)])
            }
            PBouton {
                visible: page.d.micro >= 0
                anchors.verticalCenter: parent.verticalCenter
                texte: page.d.microMuet ? "Rétablir" : "Couper"
                onClique: Etat.agirParam(["muet", "micro"])
            }
        }
        Repeater {
            model: page.d.entrees || []
            PLigne {
                required property var modelData
                glyphe: ""; teinte: modelData.nom === page.d.entreeDefaut ? "#22c55e" : "#64748b"
                titre: modelData.description
                detail: modelData.nom === page.d.entreeDefaut ? "Micro utilisé" : "Cliquer pour utiliser ce micro"
                cliquable: modelData.nom !== page.d.entreeDefaut
                onClique: Etat.agirParam(["entree", modelData.nom])
            }
        }
    }

    PCarte {
        PLigne {
            glyphe: ""; teinte: "#64748b"
            titre: "Réglages avancés du son"
            detail: "Volume par application, profils de la carte son"
            fleche: true
            separateur: false
            onClique: Etat.lancer(["pavucontrol"])
        }
    }
}
