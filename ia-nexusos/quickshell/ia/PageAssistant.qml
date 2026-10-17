// Paramètres › Assistant IA : l'assistant de NexusOS, l'IA qu'il utilise, ce qu'il peut faire
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
    property var toutes: (d.locales || []).map(x => Object.assign({ genre: "locale" }, x))
                          .concat((d.enLigne || []).map(x => Object.assign({ genre: "en-ligne" }, x)))
    property var defaut: d.defaut || ({})
    function estDefaut(x) { return defaut.type === x.genre && defaut.nom === x.nom; }
    property string nomDefaut: {
        for (let i = 0; i < toutes.length; i++) if (estDefaut(toutes[i])) return toutes[i].nom + (toutes[i].genre === "locale" ? " (locale)" : " (en ligne)");
        return toutes.length ? toutes[0].nom : "";
    }

    // ── Carte principale ──
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 104
        radius: 18
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.rgba(236/255, 72/255, 153/255, 0.22) }
            GradientStop { position: 1.0; color: Qt.rgba(47/255, 107/255, 1, 0.20) }
        }
        border.width: 1
        border.color: Qt.rgba(236/255, 72/255, 153/255, 0.40)
        RowLayout {
            anchors { fill: parent; leftMargin: 22; rightMargin: 22 }
            spacing: 16
            PIcone { glyphe: "󰙴"; teinte: "#ec4899"; taille: 52 }
            Column {
                Layout.fillWidth: true
                spacing: 3
                Text {
                    text: "Assistant NexusOS"
                    font.family: Etat.police; font.pixelSize: 19; font.weight: Font.DemiBold; color: Etat.cTexte
                }
                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: !ia.donnees ? "Lecture…"
                        : (page.nomDefaut !== "" ? "Super+A pour lui parler · utilise « " + page.nomDefaut + " »"
                                                 : "Ajoute d'abord une IA locale ou en ligne pour l'utiliser")
                    font.family: Etat.police; font.pixelSize: 12; color: Etat.cDiscret
                }
            }
            PBouton {
                texte: page.toutes.length ? "Ouvrir l'assistant" : "Ajouter une IA"
                plein: true
                onClique: page.toutes.length ? Etat.ouvrirAssistant("discussion") : Etat.ouvrirParametres("ialocales")
            }
        }
    }

    // ── IA utilisée par l'assistant ──
    PCarte {
        titre: "IA utilisée par l'assistant"
        Repeater {
            model: page.toutes
            PLigne {
                required property var modelData
                glyphe: modelData.genre === "locale" ? "" : ""
                teinte: modelData.genre === "locale" ? "#22c55e" : "#3b82f6"
                titre: modelData.nom
                detail: modelData.genre === "locale"
                        ? "Locale (Ollama) · " + modelData.modele + " · fonctionne sans Internet"
                        : "En ligne · " + modelData.fournisseurNom + " · " + modelData.modele
                Rectangle {
                    visible: page.estDefaut(modelData)
                    anchors.verticalCenter: parent.verticalCenter
                    width: badge.implicitWidth + 20; height: 26; radius: 9
                    color: Qt.rgba(34/255, 197/255, 94/255, 0.16)
                    Text { id: badge; anchors.centerIn: parent; text: "Par défaut"; font.family: Etat.police; font.pixelSize: 12; color: "#4ade80" }
                }
                PBouton {
                    visible: !page.estDefaut(modelData)
                    anchors.verticalCenter: parent.verticalCenter
                    texte: "Utiliser"
                    onClique: Etat.agirIa(["defaut", modelData.genre, modelData.nom])
                }
            }
        }
        PLigne {
            glyphe: ""; teinte: "#64748b"
            titre: "Ajouter une IA locale"
            detail: "Sur ton ordinateur avec Ollama : gratuite, privée, sans Internet"
            fleche: true
            onClique: Etat.ouvrirParametres("ialocales")
        }
        PLigne {
            glyphe: ""; teinte: "#64748b"
            titre: "Ajouter une IA en ligne"
            detail: "Avec une clé API : Mistral, Gemini, OpenAI, Claude, OpenRouter, Groq…"
            fleche: true
            separateur: false
            onClique: Etat.ouvrirParametres("iaenligne")
        }
    }

    // ── Ce que l'assistant peut faire ──
    Text {
        text: "Ce que l'assistant peut faire"
        font.family: Etat.police; font.pixelSize: 12; font.weight: Font.DemiBold; color: Etat.cDiscret
        Layout.leftMargin: 4
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 12
        Repeater {
            model: [
                { mode: "cv",         glyphe: "", teinte: "#3b82f6", titre: "CV et lettres",  detail: "Crée un document LibreOffice" },
                { mode: "maquette",   glyphe: "", teinte: "#f59e0b", titre: "Maquettes",      detail: "Page ou écran d'appli (HTML)" },
                { mode: "discussion", glyphe: "", teinte: "#22c55e", titre: "Tâches simples", detail: "Résumer, traduire, expliquer" }
            ]
            Rectangle {
                id: tuile
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 112
                radius: 16
                color: zoneTuile.containsMouse ? Qt.rgba(79/255, 139/255, 1, 0.10) : Qt.rgba(1, 1, 1, 0.04)
                border.width: 1
                border.color: Qt.rgba(154/255, 168/255, 214/255, 0.18)
                Column {
                    anchors { left: parent.left; top: parent.top; margins: 16 }
                    spacing: 8
                    PIcone { glyphe: tuile.modelData.glyphe; teinte: tuile.modelData.teinte; taille: 34 }
                    Text { text: tuile.modelData.titre; font.family: Etat.police; font.pixelSize: 14; font.weight: Font.DemiBold; color: Etat.cTexte }
                    Text { text: tuile.modelData.detail; font.family: Etat.police; font.pixelSize: 12; color: Etat.cDiscret }
                }
                MouseArea {
                    id: zoneTuile
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Etat.ouvrirAssistant(tuile.modelData.mode)
                }
            }
        }
    }

    // ── Autorisations ──
    PCarte {
        titre: "Autorisations"
        PLigne {
            glyphe: ""; teinte: "#0ea5e9"
            titre: "Créer des fichiers"
            detail: "Seulement dans le dossier IA › Créations"
            PInterrupteur {
                anchors.verticalCenter: parent.verticalCenter
                coche: !page.d.autorisations || page.d.autorisations.creer !== false
                onBascule: v => Etat.agirIa(["autorisation", "creer", v ? "on" : "off"])
            }
        }
        PLigne {
            glyphe: ""; teinte: "#64748b"
            titre: "Lire mes documents"
            detail: "L'assistant ne lit aucun de tes fichiers (bientôt : au cas par cas, avec ton accord)"
            valeur: "Désactivé"
        }
        PLigne {
            glyphe: ""; teinte: "#f59e0b"
            titre: "Mes créations"
            detail: (page.d.dossiers && page.d.dossiers.creations) || "~/IA/Créations"
            fleche: true
            onClique: Etat.lancer(["sh", "-c", 'mkdir -p "$1" && thunar "$1"', "sh", (page.d.dossiers || {}).creations])
        }
        PLigne {
            glyphe: ""; teinte: "#ef4444"
            titre: "Effacer la conversation"
            detail: (page.d.conversation || []).length + " message(s) gardés dans ~/IA/Assistant"
            separateur: false
            PBouton {
                anchors.verticalCenter: parent.verticalCenter
                texte: "Effacer"
                danger: true
                onClique: Etat.agirIa(["nouvelle-conversation"])
            }
        }
    }

    PCarte {
        titre: "Raccourcis"
        PLigne { titre: "Super + A"; detail: "Ouvrir ou fermer l'assistant"; separateur: false }
    }
}
