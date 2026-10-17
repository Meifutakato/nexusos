// Paramètres › Agents IA : agents rangés à part, chacun dans ~/IA/Agents/<nom>/ (résultats dans travail/)
import Quickshell
import QtQuick
import ".."
import QtQuick.Layouts

ColumnLayout {
    id: page
    spacing: 14

    SourceIa { id: ia; Component.onCompleted: recharger() }
    Connections {
        target: Etat
        function onIaTerminee() { ia.recharger(); }
    }
    property var d: ia.donnees || ({})
    property var dossiers: d.dossiers || ({})
    property var toutes: (d.locales || []).map(x => ({ genre: "locale", nom: x.nom, modele: x.modele }))
                          .concat((d.enLigne || []).map(x => ({ genre: "en-ligne", nom: x.nom, modele: x.modele })))
    property string choisi: ""          // agent sélectionné pour lui donner une tâche
    property string aSupprimer: ""
    property string role: "debogueur"
    property int iaChoisie: 0

    readonly property var roles: [
        { id: "debogueur", t: "Débogueur", detail: "Analyse une erreur ou un journal", teinte: "#14b8a6" },
        { id: "codeur",    t: "Codeur",    detail: "Écrit des scripts et des fichiers", teinte: "#8b5cf6" },
        { id: "relecteur", t: "Relecteur", detail: "Vérifie un travail, signale les risques", teinte: "#f59e0b" },
        { id: "redacteur", t: "Rédacteur", detail: "Écrit la documentation", teinte: "#ec4899" },
        { id: "libre",     t: "Libre",     detail: "Tes propres consignes", teinte: "#64748b" }
    ]
    function infoRole(id) { return roles.find(r => r.id === id) || roles[4]; }
    function dossierDe(nom) { return (dossiers.agents || "") + "/" + nom; }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: bandeau.implicitHeight + 26
        radius: 14
        color: Qt.rgba(20/255, 184/255, 166/255, 0.10)
        border.width: 1
        border.color: Qt.rgba(20/255, 184/255, 166/255, 0.35)
        Text {
            id: bandeau
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 16 }
            wrapMode: Text.WordWrap
            textFormat: Text.StyledText
            text: "Espace séparé : chaque agent a son propre dossier dans <b>~/IA/Agents</b>, à l'écart de tes fichiers personnels et des IA."
            font.family: Etat.police; font.pixelSize: 13; color: Etat.cTexte
        }
    }

    // ── Mes agents ──
    PCarte {
        titre: "Mes agents"
        Repeater {
            model: page.d.agents || []
            PLigne {
                required property var modelData
                glyphe: "󰚩"
                teinte: modelData.actif ? page.infoRole(modelData.role).teinte : "#475569"
                titre: modelData.nom + (page.choisi === modelData.nom ? "  ·  sélectionné" : "")
                detail: page.infoRole(modelData.role).t + " · IA : " + (modelData.ia || {}).nom
                        + " · " + modelData.resultats + " résultat(s)" + (modelData.actif ? "" : " · désactivé")
                cliquable: true
                onClique: page.choisi = (page.choisi === modelData.nom ? "" : modelData.nom)
                PInterrupteur {
                    anchors.verticalCenter: parent.verticalCenter
                    coche: !!modelData.actif
                    onBascule: v => Etat.agirIa(["agent-actif", modelData.nom, v ? "on" : "off"])
                }
            }
        }
        PLigne {
            visible: !!ia.donnees && (page.d.agents || []).length === 0
            glyphe: ""; teinte: "#64748b"
            titre: "Aucun agent pour l'instant"
            detail: page.toutes.length ? "Crée ton premier agent ci-dessous." : "Ajoute d'abord une IA (locale ou en ligne) : l'agent s'en sert pour travailler."
            separateur: false
        }
    }

    // ── Donner une tâche à l'agent sélectionné ──
    PCarte {
        visible: page.choisi !== ""
        titre: "Donner une tâche à « " + page.choisi + " »"
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 18
            spacing: 10
            PChamp {
                id: champTache
                Layout.fillWidth: true
                indication: "ex. Explique cette erreur : …"
                onValide: boutonLancer.clique()
            }
            PBouton {
                id: boutonLancer
                texte: Etat.iaOccupee ? "L'agent travaille…" : "Lancer"
                plein: true
                actif: !Etat.iaOccupee && champTache.texte.trim() !== ""
                onClique: {
                    if (!actif) return;
                    Etat.agirIa(["lancer-agent", page.choisi, champTache.texte.trim()]);
                    champTache.texte = "";
                }
            }
        }
        PLigne {
            glyphe: ""; teinte: "#f59e0b"
            titre: "Résultats de l'agent"
            detail: page.dossierDe(page.choisi) + "/travail"
            fleche: true
            onClique: Etat.lancer(["sh", "-c", 'mkdir -p "$1" && thunar "$1"', "sh", page.dossierDe(page.choisi) + "/travail"])
        }
        PLigne {
            glyphe: ""; teinte: "#ef4444"
            titre: "Supprimer cet agent"
            detail: "Supprime aussi son dossier et ses résultats"
            separateur: false
            PBouton {
                anchors.verticalCenter: parent.verticalCenter
                texte: page.aSupprimer === page.choisi ? "Confirmer ?" : "Supprimer"
                danger: true
                onClique: {
                    if (page.aSupprimer === page.choisi) {
                        Etat.agirIa(["supprimer-agent", page.choisi]);
                        page.aSupprimer = ""; page.choisi = "";
                    } else page.aSupprimer = page.choisi;
                }
            }
        }
    }

    // ── Créer un agent ──
    PCarte {
        titre: "Ajouter un agent"
        visible: page.toutes.length > 0
        Repeater {
            model: page.roles
            PLigne {
                required property var modelData
                glyphe: page.role === modelData.id ? "" : "󰚩"
                teinte: page.role === modelData.id ? Etat.cAccent2 : modelData.teinte
                titre: modelData.t
                detail: modelData.detail
                cliquable: true
                onClique: { page.role = modelData.id; if (champAgent.texte === "" || page.roles.some(r => r.t === champAgent.texte)) champAgent.texte = modelData.t; }
            }
        }
        GridLayout {
            Layout.fillWidth: true
            Layout.margins: 18
            columns: 2
            columnSpacing: 12
            rowSpacing: 10
            Text { text: "Nom"; font.family: Etat.police; font.pixelSize: 13; color: Etat.cDiscret }
            PChamp { id: champAgent; Layout.fillWidth: true; texte: "Débogueur"; indication: "ex. Débogueur" }
            Text { text: "IA utilisée"; font.family: Etat.police; font.pixelSize: 13; color: Etat.cDiscret; Layout.alignment: Qt.AlignTop; Layout.topMargin: 8 }
            Flow {
                Layout.fillWidth: true
                spacing: 8
                Repeater {
                    model: page.toutes
                    PBouton {
                        required property var modelData
                        required property int index
                        texte: modelData.nom + (modelData.genre === "locale" ? " · locale" : " · en ligne")
                        plein: page.iaChoisie === index
                        onClique: page.iaChoisie = index
                    }
                }
            }
            Text { text: "Consignes"; font.family: Etat.police; font.pixelSize: 13; color: Etat.cDiscret }
            PChamp {
                id: champConsignes
                Layout.fillWidth: true
                indication: page.role === "libre" ? "Ce que l'agent doit faire, à chaque tâche" : "facultatif (sinon celles du rôle)"
            }
            Item { width: 1; height: 1 }
            PBouton {
                texte: "Créer l'agent"
                plein: true
                actif: champAgent.texte.trim() !== "" && page.toutes.length > 0
                onClique: {
                    const cible = page.toutes[Math.min(page.iaChoisie, page.toutes.length - 1)];
                    const args = ["ajouter-agent", champAgent.texte.trim(), page.role, cible.genre, cible.nom];
                    if (champConsignes.texte.trim() !== "") args.push(champConsignes.texte.trim());
                    Etat.agirIa(args);
                    champConsignes.texte = "";
                }
            }
        }
    }

    // ── Réglages ──
    PCarte {
        titre: "Réglages des agents"
        PLigne {
            glyphe: ""; teinte: "#0ea5e9"
            titre: "Dossier des agents"
            detail: page.dossiers.agents || "~/IA/Agents"
            fleche: true
            onClique: Etat.lancer(["sh", "-c", 'mkdir -p "$1" && thunar "$1"', "sh", page.dossiers.agents])
        }
        PLigne {
            glyphe: ""; teinte: "#22c55e"
            titre: "Un agent à la fois"
            detail: "Économise la mémoire : les agents travaillent l'un après l'autre"
            valeur: "Toujours"
        }
        PLigne {
            glyphe: ""; teinte: "#64748b"
            titre: "Accès au système"
            detail: "Un agent répond seulement : il écrit son résultat dans son dossier travail/ et ne touche à rien d'autre"
            valeur: "Limité"
            separateur: false
        }
    }
}
