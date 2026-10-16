// Paramètres › Jeux : reprise de jeu, ActionReplay, lanceurs, GameMode
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    spacing: 14

    PSource { id: jeux; sujet: "jeux"; Component.onCompleted: recharger() }
    PSource { id: replay; sujet: "replay"; Component.onCompleted: recharger() }
    Connections { target: Etat; function onActionParamTerminee() { replay.recharger(); } }
    property var d: jeux.donnees || ({})
    property var r: replay.donnees || ({})

    function texteDuree(s) { return s < 60 ? s + " s" : (s / 60) + " min"; }

    // ── Reprise de jeu ──
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 96
        radius: 18
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.rgba(139/255, 92/255, 246/255, 0.30) }
            GradientStop { position: 1.0; color: Qt.rgba(47/255, 107/255, 1, 0.20) }
        }
        border.width: 1
        border.color: Qt.rgba(139/255, 92/255, 246/255, 0.45)
        RowLayout {
            anchors { fill: parent; leftMargin: 22; rightMargin: 22 }
            spacing: 16
            PIcone { glyphe: ""; teinte: "#a855f7"; taille: 48 }
            Column {
                Layout.fillWidth: true
                spacing: 3
                Text {
                    text: page.r.dernierJeu && page.r.dernierJeu.nom ? page.r.dernierJeu.nom : "Aucun jeu récent"
                    font.family: Etat.police; font.pixelSize: 18; font.weight: Font.DemiBold; color: Etat.cTexte
                }
                Text {
                    text: page.r.dernierJeu && page.r.dernierJeu.nom ? "Dernier jeu Steam · Super+G pour le relancer"
                                                                     : "Le dernier jeu Steam lancé apparaîtra ici"
                    font.family: Etat.police; font.pixelSize: 12; color: Etat.cDiscret
                }
            }
            PBouton {
                visible: !!(page.r.dernierJeu && page.r.dernierJeu.nom)
                texte: "Reprendre"
                plein: true
                onClique: { Etat.agirParam(["reprise"]); Etat.parametresOuverts = false; }
            }
        }
    }

    // ── ActionReplay ──
    PCarte {
        titre: "ActionReplay — enregistrer les dernières secondes"

        PLigne {
            glyphe: ""; teinte: "#ef4444"
            titre: "ActionReplay"
            detail: !replay.donnees ? "Lecture…"
                  : (!page.r.installe ? "gpu-screen-recorder n'est pas installé (relance l'installeur du thème)"
                  : (page.r.enCours ? "Actif · Super+Maj+G garde les " + page.texteDuree(page.r.duree) + " précédentes"
                  : (page.r.actif ? "Activé mais arrêté (voir la notification)" : "Désactivé")))
            PInterrupteur {
                anchors.verticalCenter: parent.verticalCenter
                actif: !!page.r.installe
                coche: !!page.r.actif
                onBascule: v => Etat.agirParam(["replay-actif", v ? "on" : "off"])
            }
        }

        PLigne {
            glyphe: ""; teinte: "#f59e0b"
            titre: "Durée gardée en mémoire"
            separateur: false
        }
        Flow {
            Layout.fillWidth: true
            Layout.leftMargin: 66; Layout.rightMargin: 18; Layout.bottomMargin: 12
            spacing: 8
            Repeater {
                model: [15, 30, 60, 120, 300]
                PBouton {
                    required property int modelData
                    texte: page.texteDuree(modelData)
                    plein: page.r.duree === modelData
                    onClique: Etat.agirParam(["replay-reglage", "DUREE", String(modelData)])
                }
            }
        }

        PLigne {
            glyphe: ""; teinte: "#8b5cf6"
            titre: "Qualité"
            detail: page.r.vm ? "Dans VirtualBox : encodage par le processeur, 30 images/s maximum" : ""
            separateur: false
        }
        Flow {
            Layout.fillWidth: true
            Layout.leftMargin: 66; Layout.rightMargin: 18; Layout.bottomMargin: 12
            spacing: 8
            Repeater {
                model: [ { v: "medium", t: "Normale" }, { v: "high", t: "Haute" },
                         { v: "very_high", t: "Très haute" }, { v: "ultra", t: "Maximale" } ]
                PBouton {
                    required property var modelData
                    texte: modelData.t
                    plein: page.r.qualite === modelData.v
                    onClique: Etat.agirParam(["replay-reglage", "QUALITE", modelData.v])
                }
            }
            Rectangle { width: 1; height: 34; color: Qt.rgba(154/255, 168/255, 214/255, 0.25) }
            Repeater {
                model: [30, 60]
                PBouton {
                    required property int modelData
                    texte: modelData + " images/s"
                    plein: page.r.ips === modelData
                    onClique: Etat.agirParam(["replay-reglage", "IPS", String(modelData)])
                }
            }
        }

        PLigne {
            glyphe: ""; teinte: "#ec4899"
            titre: "Enregistrer le son du jeu"
            PInterrupteur {
                anchors.verticalCenter: parent.verticalCenter
                coche: page.r.son !== false
                onBascule: v => Etat.agirParam(["replay-reglage", "SON", v ? "oui" : "non"])
            }
        }
        PLigne {
            glyphe: ""; teinte: "#0ea5e9"
            titre: "Mes clips"
            detail: (page.r.clips || 0) + " clip(s) · " + (page.r.dossier || "")
            fleche: true
            onClique: Etat.lancer(["sh", "-c", 'mkdir -p "$1" && thunar "$1"', "sh", page.r.dossier])
        }
        PLigne {
            glyphe: ""; teinte: "#ef4444"
            titre: "Enregistrer maintenant"
            detail: "Même chose que Super+Maj+G"
            separateur: false
            PBouton {
                anchors.verticalCenter: parent.verticalCenter
                actif: !!page.r.enCours
                texte: "Enregistrer le clip"
                plein: true
                onClique: Etat.agirParam(["replay-sauver"])
            }
        }
    }

    // ── Lanceurs ──
    PCarte {
        titre: "Lanceurs de jeux"
        Repeater {
            model: page.d.lanceurs || []
            PLigne {
                required property var modelData
                required property int index
                glyphe: ""; teinte: modelData.installe ? "#a855f7" : "#64748b"
                titre: modelData.nom
                detail: modelData.installe ? "Installé" : "Pas installé"
                separateur: index < (page.d.lanceurs || []).length - 1
                PBouton {
                    visible: modelData.installe
                    anchors.verticalCenter: parent.verticalCenter
                    texte: "Ouvrir"
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
            glyphe: ""; teinte: "#ec4899"
            titre: "GameMode"
            detail: page.d.gamemode ? "Installé — s'active tout seul quand un jeu le demande (Steam : gamemoderun %command%)"
                                    : "Pas installé"
            separateur: false
        }
    }

    PCarte {
        titre: "GameResume"
        PLigne {
            glyphe: "\uf044"; teinte: "#14b8a6"
            titre: "Notes de session"
            detail: "Temps de jeu et notes par jeu (nexus-gameresume)"
            fleche: true
            separateur: false
            onClique: Etat.lancer(["kitty", "--hold", "nexus-gameresume", "--list"])
        }
    }

    PCarte {
        titre: "Raccourcis"
        PLigne { titre: "Super + G"; detail: "Reprendre le dernier jeu" }
        PLigne { titre: "Super + Maj + G"; detail: "Enregistrer le clip ActionReplay"; separateur: false }
    }
}
