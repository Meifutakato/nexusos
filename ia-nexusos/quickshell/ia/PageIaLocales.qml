// Paramètres › IA locales : IA qui tournent sur l'ordinateur avec Ollama (rangées dans ~/IA/Locales)
import Quickshell
import Quickshell.Io
import QtQuick
import ".."
import QtQuick.Layouts

ColumnLayout {
    id: page
    spacing: 14

    // Lecture de l'état de l'espace IA (nexus-ia etat)
    Item {
        id: ia
        visible: false
        property var donnees: null
        function recharger() { if (!lecteurIa.running) lecteurIa.running = true; }
        Process {
            id: lecteurIa
            command: ["nexus-ia", "etat"]
            stdout: SplitParser {
                onRead: ligne => {
                    try { ia.donnees = JSON.parse(ligne); } catch (e) {}
                }
            }
        }
        Component.onCompleted: recharger()
    }
    Connections {
        target: Etat
        function onIaTerminee() { ia.recharger(); }
    }
    // Relecture régulière : voit un téléchargement de modèle ou une installation terminés dans le terminal
    Timer { interval: 6000; running: true; repeat: true; onTriggered: ia.recharger() }
    property var d: ia.donnees || ({})
    property var dossiers: d.dossiers || ({})
    property string aSupprimer: ""
    property string modeleChoisi: "qwen2.5:1.5b"

    readonly property var suggestions: [
        { m: "qwen2.5:1.5b",      t: "Qwen 2.5 — 1,5 B",       detail: "≈ 1 Go · très léger, idéal pour démarrer" },
        { m: "llama3.2:3b",       t: "Llama 3.2 — 3 B",        detail: "≈ 2 Go · bon en français" },
        { m: "qwen2.5-coder:3b",  t: "Qwen 2.5 Coder — 3 B",   detail: "≈ 2 Go · code et maquettes" },
        { m: "mistral:7b",        t: "Mistral — 7 B",          detail: "≈ 4 Go · plus précis, 8 Go de RAM conseillés" }
    ]

    // ── Ollama ──
    PCarte {
        titre: "Moteur des IA locales"
        PLigne {
            glyphe: ""; teinte: page.d.ollamaActif ? "#22c55e" : "#64748b"
            titre: "Ollama"
            detail: !ia.donnees ? "Lecture…"
                  : (page.d.ollamaActif ? "Démarré · " + (page.d.modelesOllama || []).length + " modèle(s) téléchargé(s)"
                  : (page.d.ollamaInstalle ? "Installé mais arrêté" : "Pas installé — nécessaire pour les IA locales"))
            separateur: false
            PBouton {
                visible: !!ia.donnees && !page.d.ollamaInstalle
                anchors.verticalCenter: parent.verticalCenter
                texte: "Installer"
                plein: true
                onClique: Etat.lancer(["kitty", "--title", "Installation d'Ollama", "sh", "-c",
                    "sudo pacman -S --needed ollama && sudo systemctl enable --now ollama && echo && echo 'Ollama est prêt. Tu peux fermer cette fenêtre.'; read -r _"])
            }
            PBouton {
                visible: !!page.d.ollamaInstalle && !page.d.ollamaActif
                anchors.verticalCenter: parent.verticalCenter
                texte: "Démarrer"
                plein: true
                onClique: Etat.lancer(["pkexec", "systemctl", "enable", "--now", "ollama"])
            }
        }
    }

    // ── Mes IA locales ──
    PCarte {
        titre: "Mes IA locales"
        Repeater {
            model: page.d.locales || []
            PLigne {
                required property var modelData
                glyphe: ""; teinte: "#22c55e"
                titre: modelData.nom
                detail: modelData.modele + " · "
                        + (modelData.telecharge ? "prêt" : (page.d.ollamaActif ? "modèle pas encore téléchargé" : "Ollama arrêté"))
                        + ((page.d.defaut || {}).type === "locale" && (page.d.defaut || {}).nom === modelData.nom ? " · par défaut" : "")
                PBouton {
                    visible: !modelData.telecharge && !!page.d.ollamaActif
                    anchors.verticalCenter: parent.verticalCenter
                    texte: "Télécharger"
                    plein: true
                    onClique: Etat.lancer(["kitty", "--title", "Téléchargement du modèle", "sh", "-c",
                        'ollama pull "$1" && echo && echo "Modèle prêt. Tu peux fermer cette fenêtre."; read -r _', "sh", modelData.modele])
                }
                PBouton {
                    visible: !!modelData.telecharge
                    anchors.verticalCenter: parent.verticalCenter
                    actif: !Etat.iaOccupee
                    texte: Etat.iaOccupee ? "…" : "Tester"
                    onClique: Etat.agirIa(["tester", "locale", modelData.nom])
                }
                PBouton {
                    visible: !((page.d.defaut || {}).type === "locale" && (page.d.defaut || {}).nom === modelData.nom)
                    anchors.verticalCenter: parent.verticalCenter
                    texte: "Par défaut"
                    onClique: Etat.agirIa(["defaut", "locale", modelData.nom])
                }
                PBouton {
                    anchors.verticalCenter: parent.verticalCenter
                    texte: page.aSupprimer === modelData.nom ? "Confirmer ?" : "Retirer"
                    danger: true
                    onClique: {
                        if (page.aSupprimer === modelData.nom) { Etat.agirIa(["supprimer", "locale", modelData.nom]); page.aSupprimer = ""; }
                        else page.aSupprimer = modelData.nom;
                    }
                }
            }
        }
        PLigne {
            visible: !!ia.donnees && (page.d.locales || []).length === 0
            glyphe: ""; teinte: "#64748b"
            titre: "Aucune IA locale pour l'instant"
            detail: "Ajoute-en une ci-dessous."
        }
        PLigne {
            glyphe: ""; teinte: "#f59e0b"
            titre: "Dossier des IA locales"
            detail: page.dossiers.locales || "~/IA/Locales"
            fleche: true
            separateur: false
            onClique: Etat.lancer(["sh", "-c", 'mkdir -p "$1" && thunar "$1"', "sh", page.dossiers.locales])
        }
    }

    // ── Ajouter ──
    PCarte {
        titre: "Ajouter une IA locale"
        Repeater {
            model: page.suggestions
            PLigne {
                required property var modelData
                glyphe: page.modeleChoisi === modelData.m ? "" : ""
                teinte: page.modeleChoisi === modelData.m ? Etat.cAccent2 : "#475569"
                titre: modelData.t
                detail: modelData.m + " · " + modelData.detail
                cliquable: true
                onClique: { page.modeleChoisi = modelData.m; champModele.texte = modelData.m; if (champNom.texte === "") champNom.texte = modelData.t; }
            }
        }
        GridLayout {
            Layout.fillWidth: true
            Layout.margins: 18
            columns: 2
            columnSpacing: 12
            rowSpacing: 10
            Text { text: "Nom"; font.family: Etat.police; font.pixelSize: 13; color: Etat.cDiscret }
            PChamp { id: champNom; Layout.fillWidth: true; indication: "ex. Qwen petit" }
            Text { text: "Modèle Ollama"; font.family: Etat.police; font.pixelSize: 13; color: Etat.cDiscret }
            PChamp { id: champModele; Layout.fillWidth: true; texte: "qwen2.5:1.5b"; indication: "nom sur ollama.com/library" }
            Item { width: 1; height: 1 }
            RowLayout {
                spacing: 10
                PBouton {
                    texte: "Ajouter"
                    plein: true
                    actif: champNom.texte.trim() !== "" && champModele.texte.trim() !== ""
                    onClique: {
                        Etat.agirIa(["ajouter-locale", champNom.texte.trim(), champModele.texte.trim()]);
                        champNom.texte = "";
                    }
                }
                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: "Ensuite, clique sur « Télécharger » pour récupérer le modèle."
                    font.family: Etat.police; font.pixelSize: 12; color: Etat.cDiscret
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        wrapMode: Text.WordWrap
        text: "Les IA locales sont rangées à part des IA en ligne. Dans VirtualBox elles seront lentes (pas de carte graphique) : les vrais essais se feront en dual boot."
        font.family: Etat.police; font.pixelSize: 12; color: Etat.cDiscret
    }
}
