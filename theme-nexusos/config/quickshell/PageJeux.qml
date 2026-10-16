// Paramètres › Jeux : lanceurs, GameMode, enregistrements
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    spacing: 14

    PSource { id: jeux; sujet: "jeux"; Component.onCompleted: recharger() }
    property var d: jeux.donnees || ({})

    PCarte {
        titre: "Lanceurs de jeux"
        Repeater {
            model: page.d.lanceurs || []
            PLigne {
                required property var modelData
                required property int index
                glyphe: "\uf11b"; teinte: modelData.installe ? "#a855f7" : "#64748b"
                titre: modelData.nom
                detail: modelData.installe ? "Installé" : "Pas encore installé (phase 6)"
                separateur: index < (page.d.lanceurs || []).length - 1
                PBouton {
                    visible: modelData.installe
                    anchors.verticalCenter: parent.verticalCenter
                    texte: "Ouvrir"
                    plein: true
                    onClique: {
                        const e = DesktopEntries.byId(modelData.id);
                        if (e) e.execute(); else Etat.lancer([modelData.id]);
                    }
                }
            }
        }
    }

    PCarte {
        titre: "Performances"
        PLigne {
            glyphe: "\uf135"; teinte: "#ec4899"
            titre: "GameMode"
            detail: page.d.gamemode ? "Installé — s'active tout seul quand un jeu le demande"
                                    : "Optimise le processeur pendant les jeux (sera installé avec la phase 6)"
            separateur: false
        }
    }

    PCarte {
        titre: "Enregistrements"
        PLigne {
            glyphe: "\uf03d"; teinte: "#ef4444"
            titre: "Clips de jeu"
            detail: page.d.clips ? page.d.clips : "Dossier des clips pas encore créé"
            fleche: !!page.d.clips
            onClique: Etat.lancer(["thunar", page.d.clips])
        }
        PLigne {
            glyphe: "\uf01d"; teinte: "#64748b"
            titre: "ActionReplay"
            detail: "Enregistrer les dernières minutes de jeu (Super+Maj+G) — version Wayland à venir"
            separateur: false
        }
    }

    PCarte {
        titre: "Raccourcis"
        PLigne { titre: "Super + G"; detail: "Reprendre le dernier jeu" }
        PLigne { titre: "Super + Maj + G"; detail: "Enregistrer les dernières minutes"; separateur: false }
    }
}
