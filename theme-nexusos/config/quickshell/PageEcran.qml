// Paramètres › Écran : résolution et échelle
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    spacing: 14

    PSource { id: ecr; sujet: "ecran"; Component.onCompleted: recharger() }
    Connections { target: Etat; function onActionParamTerminee() { ecr.recharger(); } }

    Repeater {
        model: ecr.donnees ? ecr.donnees.ecrans : []
        PCarte {
            id: carteEcran
            required property var modelData
            titre: "Écran " + modelData.nom + (modelData.description ? " — " + modelData.description : "")
            property string modeActuel: modelData.largeur + "x" + modelData.hauteur + "@" + modelData.frequence
            property string echelleActuelle: String(modelData.echelle)

            PLigne {
                glyphe: ""; teinte: "#0ea5e9"
                titre: "Résolution"
                detail: "Actuelle : " + carteEcran.modelData.largeur + " × " + carteEcran.modelData.hauteur + " à " + carteEcran.modelData.frequence + " Hz"
            }
            Flow {
                Layout.fillWidth: true
                Layout.leftMargin: 66; Layout.rightMargin: 18; Layout.bottomMargin: 14
                spacing: 8
                Repeater {
                    model: carteEcran.modelData.modes
                    PBouton {
                        required property string modelData
                        texte: modelData.replace("x", " × ").replace("@", "  ·  ") + " Hz"
                        plein: modelData === carteEcran.modeActuel
                        onClique: Etat.agirParam(["ecran-mode", carteEcran.modelData.nom, modelData, carteEcran.echelleActuelle])
                    }
                }
            }
            PLigne {
                glyphe: ""; teinte: "#8b5cf6"
                titre: "Échelle"
                detail: "Agrandit le texte et les fenêtres (utile sur un grand écran)"
            }
            Flow {
                Layout.fillWidth: true
                Layout.leftMargin: 66; Layout.rightMargin: 18; Layout.bottomMargin: 14
                spacing: 8
                Repeater {
                    model: ["1", "1.25", "1.5", "2"]
                    PBouton {
                        required property string modelData
                        texte: Math.round(parseFloat(modelData) * 100) + " %"
                        plein: Math.abs(parseFloat(modelData) - parseFloat(carteEcran.echelleActuelle)) < 0.01
                        onClique: Etat.agirParam(["ecran-mode", carteEcran.modelData.nom, carteEcran.modeActuel, modelData])
                    }
                }
            }
        }
    }

    PCarte {
        visible: !ecr.donnees || ecr.donnees.ecrans.length === 0
        PLigne { titre: "Lecture des écrans…"; separateur: false }
    }

    Text {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: "Le réglage choisi est gardé après redémarrage. Dans VirtualBox, choisis une résolution qui tient dans la fenêtre de la VM."
        font.family: Etat.police; font.pixelSize: 12; color: Etat.cDiscret
    }
}
