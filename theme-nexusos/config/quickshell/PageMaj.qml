// Paramètres › Mise à jour et sauvegarde
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    spacing: 14

    PSource { id: infos; sujet: "infos"; Component.onCompleted: recharger() }
    PSource { id: snaps; sujet: "snapshots"; Component.onCompleted: recharger() }
    Connections { target: Etat; function onActionParamTerminee() { snaps.recharger(); infos.recharger(); } }
    property var d: infos.donnees || ({})

    PCarte {
        titre: "Mises à jour"
        PLigne {
            glyphe: ""; teinte: "#3b82f6"
            titre: "Mettre à jour NexusOS"
            detail: "Dernière mise à jour complète : " + Etat.depuis(page.d.derniereMaj)
            separateur: false
            PBouton {
                anchors.verticalCenter: parent.verticalCenter
                texte: "Mettre à jour"
                plein: true
                onClique: Etat.lancer(["kitty", "--title", "Mise à jour NexusOS", "sh", "-c",
                    "echo 'Mise à jour de NexusOS (ton mot de passe sera demandé)'; echo; sudo pacman -Syu; command -v paru >/dev/null && paru -Sua; echo; read -p 'Terminé. Appuie sur Entrée pour fermer' r"])
            }
        }
    }

    PCarte {
        titre: "Snapshots de sécurité (Btrfs)"
        PLigne {
            glyphe: ""; teinte: "#22c55e"
            titre: "Créer un snapshot maintenant"
            detail: "Photo instantanée du système, à faire avant un gros changement"
            PBouton {
                anchors.verticalCenter: parent.verticalCenter
                texte: "Créer"
                onClique: Etat.agirParam(["snapshot"])
            }
        }
        Repeater {
            model: snaps.donnees ? snaps.donnees.snapshots : []
            PLigne {
                required property var modelData
                glyphe: ""; teinte: "#64748b"
                titre: modelData.nom
                detail: new Date(modelData.date * 1000).toLocaleString(Qt.locale("fr_FR"), "d MMMM yyyy à HH:mm")
            }
        }
        PLigne {
            visible: !snaps.donnees || snaps.donnees.snapshots.length === 0
            titre: "Aucun snapshot trouvé"
            separateur: false
        }
    }

    Text {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: "Revenir à un snapshot se fait pour l'instant à la main (c'est une opération délicate) ; un bouton sûr arrivera plus tard."
        font.family: Etat.police; font.pixelSize: 12; color: Etat.cDiscret
    }
}
