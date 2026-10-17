// Paramètres › IA en ligne : IA de fournisseurs (clé API), rangées dans ~/IA/En-ligne,
// les clés à part dans ~/.config/nexusos/ia-cles.json (lisible par toi seul)
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
    property var d: ia.donnees || ({})
    property var dossiers: d.dossiers || ({})
    property string aSupprimer: ""
    property string fournisseur: "mistral"

    // Modèle proposé pour chaque fournisseur (modifiable)
    readonly property var modeles: ({
        mistral: "mistral-small-latest", gemini: "gemini-2.5-flash", openai: "gpt-4o-mini",
        anthropic: "claude-haiku-5-5", openrouter: "openrouter/auto", groq: "llama-3.3-70b-versatile", autre: ""
    })
    readonly property var sites: ({
        mistral: "console.mistral.ai", gemini: "aistudio.google.com", openai: "platform.openai.com",
        anthropic: "console.anthropic.com", openrouter: "openrouter.ai/keys", groq: "console.groq.com", autre: ""
    })
    function choisir(id) {
        fournisseur = id;
        champModele.texte = modeles[id] || "";
        // On ne remplace le nom que s'il est vide ou si c'est encore le nom d'un fournisseur
        const noms = (d.fournisseurs || []).map(x => x.nom);
        if (champNom.texte === "" || noms.indexOf(champNom.texte) >= 0) {
            const f = (d.fournisseurs || []).find(x => x.id === id);
            champNom.texte = id === "autre" ? "" : (f ? f.nom : id);
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: bandeau.implicitHeight + 26
        radius: 14
        color: Qt.rgba(59/255, 130/255, 246/255, 0.10)
        border.width: 1
        border.color: Qt.rgba(59/255, 130/255, 246/255, 0.35)
        Text {
            id: bandeau
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 16 }
            wrapMode: Text.WordWrap
            textFormat: Text.StyledText
            text: "Espace séparé : chaque IA en ligne a son dossier dans <b>~/IA/En-ligne</b>. "
                + "Les clés API sont gardées à part, lisibles par toi seul, et ne sont jamais affichées."
            font.family: Etat.police; font.pixelSize: 13; color: Etat.cTexte
        }
    }

    // ── Mes IA en ligne ──
    PCarte {
        titre: "Mes IA en ligne"
        Repeater {
            model: page.d.enLigne || []
            PLigne {
                required property var modelData
                property bool parDefaut: (page.d.defaut || {}).type === "en-ligne" && (page.d.defaut || {}).nom === modelData.nom
                glyphe: ""; teinte: "#3b82f6"
                titre: modelData.nom
                detail: modelData.fournisseurNom + " · " + modelData.modele + " · "
                        + (modelData.cle ? "clé API enregistrée" : "clé manquante") + (parDefaut ? " · par défaut" : "")
                PBouton {
                    anchors.verticalCenter: parent.verticalCenter
                    actif: !Etat.iaOccupee
                    texte: Etat.iaOccupee ? "…" : "Tester"
                    onClique: Etat.agirIa(["tester", "en-ligne", modelData.nom])
                }
                PBouton {
                    visible: !parDefaut
                    anchors.verticalCenter: parent.verticalCenter
                    texte: "Par défaut"
                    onClique: Etat.agirIa(["defaut", "en-ligne", modelData.nom])
                }
                PBouton {
                    anchors.verticalCenter: parent.verticalCenter
                    texte: page.aSupprimer === modelData.nom ? "Confirmer ?" : "Retirer"
                    danger: true
                    onClique: {
                        if (page.aSupprimer === modelData.nom) { Etat.agirIa(["supprimer", "en-ligne", modelData.nom]); page.aSupprimer = ""; }
                        else page.aSupprimer = modelData.nom;
                    }
                }
            }
        }
        PLigne {
            visible: !!ia.donnees && (page.d.enLigne || []).length === 0
            glyphe: ""; teinte: "#64748b"
            titre: "Aucune IA en ligne pour l'instant"
            detail: "Ajoute-en une ci-dessous avec ta clé API."
        }
        PLigne {
            glyphe: ""; teinte: "#f59e0b"
            titre: "Dossier des IA en ligne"
            detail: page.dossiers.enLigne || "~/IA/En-ligne"
            fleche: true
            separateur: false
            onClique: Etat.lancer(["sh", "-c", 'mkdir -p "$1" && thunar "$1"', "sh", page.dossiers.enLigne])
        }
    }

    // ── Ajouter ──
    PCarte {
        titre: "Ajouter une IA en ligne"
        Flow {
            Layout.fillWidth: true
            Layout.margins: 18
            Layout.bottomMargin: 6
            spacing: 8
            Repeater {
                model: page.d.fournisseurs || []
                PBouton {
                    required property var modelData
                    texte: modelData.nom
                    plein: page.fournisseur === modelData.id
                    onClique: page.choisir(modelData.id)
                }
            }
        }
        GridLayout {
            Layout.fillWidth: true
            Layout.margins: 18
            columns: 2
            columnSpacing: 12
            rowSpacing: 10
            Text { text: "Nom"; font.family: Etat.police; font.pixelSize: 13; color: Etat.cDiscret }
            PChamp {
                id: champNom
                Layout.fillWidth: true
                texte: "Mistral"
                indication: "ex. Mistral"
            }
            Text { text: "Modèle"; font.family: Etat.police; font.pixelSize: 13; color: Etat.cDiscret }
            PChamp { id: champModele; Layout.fillWidth: true; texte: "mistral-small-latest"; indication: "nom du modèle chez le fournisseur" }
            Text { text: "Clé API"; font.family: Etat.police; font.pixelSize: 13; color: Etat.cDiscret }
            PChamp {
                id: champCle
                Layout.fillWidth: true
                motDePasse: true
                indication: page.sites[page.fournisseur] ? "à créer sur " + page.sites[page.fournisseur] : "ta clé API"
            }
            Text {
                visible: page.fournisseur === "autre"
                text: "Adresse de l'API"; font.family: Etat.police; font.pixelSize: 13; color: Etat.cDiscret
            }
            PChamp {
                id: champAdresse
                visible: page.fournisseur === "autre"
                Layout.fillWidth: true
                indication: "https://…/v1 (compatible OpenAI)"
            }
            Item { width: 1; height: 1 }
            PBouton {
                texte: "Ajouter"
                plein: true
                actif: champNom.texte.trim() !== "" && champModele.texte.trim() !== "" && champCle.texte.trim() !== ""
                       && (page.fournisseur !== "autre" || champAdresse.texte.trim() !== "")
                onClique: {
                    const args = ["ajouter-en-ligne", champNom.texte.trim(), page.fournisseur,
                                  champModele.texte.trim(), champCle.texte.trim()];
                    if (page.fournisseur === "autre") args.push(champAdresse.texte.trim());
                    Etat.agirIa(args);
                    champCle.texte = "";
                    champNom.texte = "";
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        wrapMode: Text.WordWrap
        text: "Avec une IA en ligne, ce que tu écris à l'assistant est envoyé au fournisseur choisi. Pour rester privé, utilise une IA locale."
        font.family: Etat.police; font.pixelSize: 12; color: Etat.cDiscret
    }
}
