// Paramètres › Bluetooth et appareils
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    spacing: 14

    PSource { id: bt; sujet: "bluetooth"; Component.onCompleted: recharger() }
    Connections { target: Etat; function onActionParamTerminee() { bt.recharger(); } }
    property var d: bt.donnees || ({})

    PCarte {
        PLigne {
            glyphe: ""; teinte: "#2f6bff"
            titre: "Bluetooth"
            detail: !bt.donnees ? "Recherche de l'adaptateur…"
                  : (page.d.adaptateur ? (page.d.allume ? "Activé — visible par les appareils associés" : "Désactivé")
                                       : (page.d.raison || "Aucun adaptateur Bluetooth"))
            separateur: false
            PInterrupteur {
                visible: !!page.d.adaptateur
                anchors.verticalCenter: parent.verticalCenter
                coche: !!page.d.allume
                onBascule: v => Etat.agirParam(["bluetooth-etat", v ? "on" : "off"])
            }
        }
    }

    PCarte {
        titre: "Appareils associés"
        visible: !!page.d.adaptateur

        Repeater {
            model: page.d.appareils || []
            PLigne {
                required property var modelData
                glyphe: ""; teinte: modelData.connecte ? "#22c55e" : "#64748b"
                titre: modelData.nom
                detail: modelData.connecte ? "Connecté" : "Non connecté"
                PBouton {
                    anchors.verticalCenter: parent.verticalCenter
                    texte: modelData.connecte ? "Déconnecter" : "Connecter"
                    plein: !modelData.connecte
                    onClique: Etat.agirParam(["appareil", modelData.adresse, modelData.connecte ? "off" : "on"])
                }
            }
        }
        PLigne {
            visible: !page.d.appareils || page.d.appareils.length === 0
            titre: "Aucun appareil associé"
            detail: "Utilise « Ajouter un appareil » pour associer un casque, une manette, une souris…"
        }
        PLigne {
            glyphe: ""; teinte: "#2f6bff"
            titre: "Ajouter un appareil"
            detail: "Ouvre l'assistant d'association"
            fleche: true
            separateur: false
            onClique: Etat.lancer(["sh", "-c", "command -v blueman-manager >/dev/null && exec blueman-manager || exec kitty -e bluetoothctl"])
        }
    }

    PCarte {
        titre: "Autres appareils"
        PLigne {
            glyphe: ""; teinte: "#14b8a6"
            titre: "Clavier"
            detail: "Disposition française (AZERTY)"
        }
        PLigne {
            glyphe: ""; teinte: "#f59e0b"
            titre: "Clés USB et disques"
            detail: "Ouvrir le gestionnaire de fichiers"
            fleche: true
            separateur: false
            onClique: Etat.lancer(["thunar", "computer:///"])
        }
    }
}
