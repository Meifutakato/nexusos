// NexusOS — fenêtre de l'assistant IA (Super+A)
//   quickshell ipc call assistant basculer
//   quickshell ipc call assistant mode cv
// Discussion, création de CV (document LibreOffice) et de maquettes (HTML), avec l'IA par défaut.
import Quickshell
import Quickshell.Io
import QtQuick
import ".."
import QtQuick.Layouts

FloatingWindow {
    id: fenetre
    title: "Assistant NexusOS"
    visible: Etat.assistantOuvert
    implicitWidth: 640
    implicitHeight: 780
    color: "#0a1230"

    property var messages: []
    property bool attente: envoi.running
    property bool charge: false

    readonly property var modes: [
        { id: "discussion", t: "Discussion", glyphe: "", aide: "Pose une question, demande un résumé, une traduction, une explication…" },
        { id: "cv",         t: "CV",         glyphe: "", aide: "Décris ton parcours : je crée un CV que tu pourras modifier dans LibreOffice." },
        { id: "maquette",   t: "Maquette",   glyphe: "", aide: "Décris la page ou l'écran : je crée une maquette qui s'ouvre dans le navigateur." }
    ]
    readonly property var exemples: ({
        discussion: ["Résume ce texte en 3 points : …", "Traduis en anglais : …", "Explique-moi ce qu'est un snapshot Btrfs"],
        cv: ["CV de développeur web junior, 2 ans d'expérience, français et anglais",
             "Lettre de motivation pour un stage en informatique"],
        maquette: ["Page d'accueil d'un café, tons chauds, menu et horaires",
                   "Écran de connexion d'une appli mobile, style sombre"]
    })
    function infoMode(id) { return modes.find(m => m.id === id) || modes[0]; }

    SourceIa { id: ia }
    property var d: ia.donnees || ({})
    property var toutes: (d.locales || []).map(x => ({ genre: "locale", nom: x.nom }))
                          .concat((d.enLigne || []).map(x => ({ genre: "en-ligne", nom: x.nom })))
    property string iaActuelle: {
        const df = d.defaut || {};
        for (let i = 0; i < toutes.length; i++) if (toutes[i].genre === df.type && toutes[i].nom === df.nom) return toutes[i].nom;
        return toutes.length ? toutes[0].nom : "";
    }
    // Passe à l'IA suivante (devient l'IA par défaut)
    function iaSuivante() {
        if (toutes.length < 2) { Etat.ouvrirParametres("assistant"); return; }
        let i = toutes.findIndex(x => x.nom === iaActuelle);
        const s = toutes[(i + 1) % toutes.length];
        Etat.agirIa(["defaut", s.genre, s.nom]);
    }
    Connections {
        target: Etat
        function onIaTerminee() { if (fenetre.visible) ia.recharger(); }
    }
    Connections {
        target: ia
        function onDonneesChanged() {
            if (!fenetre.charge && ia.donnees) {
                fenetre.messages = (ia.donnees.conversation || []).slice();
                fenetre.charge = true;
                Qt.callLater(liste.positionViewAtEnd);
            }
        }
    }

    onVisibleChanged: {
        if (visible) { charge = false; ia.recharger(); saisie.forceActiveFocus(); }
        else Etat.assistantOuvert = false;
    }

    function ajouter(m) {
        const l = messages.slice();
        l.push(m);
        messages = l;
        Qt.callLater(liste.positionViewAtEnd);
    }
    function envoyer() {
        const t = saisie.text.trim();
        if (t === "" || envoi.running) return;
        if (toutes.length === 0) { Etat.ouvrirParametres("assistant"); return; }
        ajouter({ role: "user", content: t, mode: Etat.modeAssistant });
        saisie.text = "";
        envoi.command = ["nexus-ia", "demander", Etat.modeAssistant, t];
        envoi.running = true;
    }
    function nouvelle() {
        messages = [];
        Etat.agirIa(["nouvelle-conversation"]);
    }

    Process {
        id: envoi
        property bool recu: false
        onStarted: recu = false
        stdout: SplitParser {
            onRead: ligne => {
                try {
                    const r = JSON.parse(ligne);
                    envoi.recu = true;
                    fenetre.ajouter({ role: "assistant", content: r.message || "", fichier: r.fichier || "", erreur: !r.ok, ia: r.ia || "" });
                } catch (e) {}
            }
        }
        onExited: (code, statut) => {
            if (!recu) fenetre.ajouter({ role: "assistant", content: "Pas de réponse (code " + code + ").", erreur: true });
        }
    }

    // ── Fond ──
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0d1740" }
            GradientStop { position: 1.0; color: "#070d26" }
        }
    }

    ColumnLayout {
        anchors { fill: parent; margins: 18 }
        spacing: 12

        // ── En-tête ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            PIcone { glyphe: "󰙴"; teinte: "#ec4899"; taille: 40 }
            Column {
                Layout.fillWidth: true
                spacing: 1
                Text { text: "Assistant NexusOS"; font.family: Etat.police; font.pixelSize: 17; font.weight: Font.DemiBold; color: Etat.cTexte }
                Text {
                    text: fenetre.toutes.length === 0 ? (ia.donnees ? "Aucune IA configurée" : "…")
                                                      : "IA : " + fenetre.iaActuelle + (fenetre.toutes.length > 1 ? "  ·  cliquer pour changer" : "")
                    font.family: Etat.police; font.pixelSize: 12; color: Etat.cDiscret
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: fenetre.iaSuivante() }
                }
            }
            PBouton { texte: "Nouvelle"; onClique: fenetre.nouvelle() }
            PBouton { texte: "Réglages"; onClique: Etat.ouvrirParametres("assistant") }
        }

        // ── Modes ──
        Row {
            spacing: 8
            Repeater {
                model: fenetre.modes
                PBouton {
                    required property var modelData
                    texte: modelData.t
                    plein: Etat.modeAssistant === modelData.id
                    onClique: Etat.modeAssistant = modelData.id
                }
            }
        }

        // ── Messages ──
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 16
            color: Qt.rgba(1, 1, 1, 0.03)
            border.width: 1
            border.color: Qt.rgba(154/255, 168/255, 214/255, 0.15)

            // Écran d'accueil (aucun message)
            Column {
                visible: fenetre.messages.length === 0 && !fenetre.attente
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 28 }
                spacing: 12
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: fenetre.toutes.length === 0 && ia.donnees
                          ? "Ajoute une IA locale ou en ligne dans les Paramètres pour commencer."
                          : fenetre.infoMode(Etat.modeAssistant).aide
                    font.family: Etat.police; font.pixelSize: 14; color: Etat.cDiscret
                }
                Repeater {
                    model: fenetre.toutes.length ? (fenetre.exemples[Etat.modeAssistant] || []) : []
                    Rectangle {
                        required property string modelData
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.min(parent.width, ex.implicitWidth + 32)
                        height: ex.implicitHeight + 18
                        radius: 12
                        color: zoneEx.containsMouse ? Qt.rgba(79/255, 139/255, 1, 0.16) : Qt.rgba(1, 1, 1, 0.05)
                        border.width: 1
                        border.color: Qt.rgba(154/255, 168/255, 214/255, 0.2)
                        Text {
                            id: ex
                            anchors.centerIn: parent
                            width: Math.min(implicitWidth, parent.parent.width - 32)
                            wrapMode: Text.WordWrap
                            text: parent.modelData
                            font.family: Etat.police; font.pixelSize: 13; color: Etat.cTexte
                        }
                        MouseArea {
                            id: zoneEx
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { saisie.text = parent.modelData; saisie.forceActiveFocus(); saisie.cursorPosition = saisie.text.length; }
                        }
                    }
                }
                PBouton {
                    visible: fenetre.toutes.length === 0 && !!ia.donnees
                    anchors.horizontalCenter: parent.horizontalCenter
                    texte: "Ouvrir les Paramètres IA"
                    plein: true
                    onClique: Etat.ouvrirParametres("assistant")
                }
            }

            ListView {
                id: liste
                anchors { fill: parent; margins: 12 }
                clip: true
                spacing: 10
                model: fenetre.messages
                boundsBehavior: Flickable.StopAtBounds
                footer: Item {
                    width: liste.width
                    height: fenetre.attente ? 46 : 0
                    visible: fenetre.attente
                    Rectangle {
                        y: 10
                        width: points.implicitWidth + 28; height: 34; radius: 14
                        color: Qt.rgba(1, 1, 1, 0.07)
                        Text {
                            id: points
                            anchors.centerIn: parent
                            property int n: 1
                            text: (Etat.modeAssistant === "discussion" ? "Réflexion" : "Création en cours") + ".".repeat(n)
                            font.family: Etat.police; font.pixelSize: 13; color: Etat.cDiscret
                            Timer { interval: 450; running: fenetre.attente; repeat: true; onTriggered: points.n = points.n % 3 + 1 }
                        }
                    }
                }
                delegate: Item {
                    id: bloc
                    required property var modelData
                    property bool moi: modelData.role === "user"
                    width: liste.width
                    height: bulle.height

                    Rectangle {
                        id: bulle
                        anchors.right: bloc.moi ? parent.right : undefined
                        anchors.left: bloc.moi ? undefined : parent.left
                        width: Math.min(liste.width * 0.84, Math.max(texte.implicitWidth, boutonFichier.visible ? boutonFichier.implicitWidth : 0) + 28)
                        height: colonneBulle.implicitHeight + 20
                        radius: 14
                        color: bloc.moi ? Qt.rgba(47/255, 107/255, 1, 0.85)
                             : (bloc.modelData.erreur ? Qt.rgba(127/255, 29/255, 29/255, 0.55) : Qt.rgba(1, 1, 1, 0.07))
                        border.width: bloc.moi ? 0 : 1
                        border.color: bloc.modelData.erreur ? Qt.rgba(1, 0.42, 0.42, 0.5) : Qt.rgba(154/255, 168/255, 214/255, 0.15)
                        Column {
                            id: colonneBulle
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10; leftMargin: 14; rightMargin: 14 }
                            spacing: 8
                            Text {
                                visible: bloc.moi && !!bloc.modelData.mode && bloc.modelData.mode !== "discussion"
                                text: bloc.modelData.mode === "cv" ? "CV" : "Maquette"
                                font.family: Etat.police; font.pixelSize: 11; font.weight: Font.DemiBold; color: "#c7d7ff"
                            }
                            TextEdit {
                                id: texte
                                width: Math.min(implicitWidth, liste.width * 0.84 - 28)
                                text: bloc.modelData.content || ""
                                readOnly: true
                                selectByMouse: true
                                wrapMode: TextEdit.Wrap
                                textFormat: TextEdit.PlainText
                                font.family: Etat.police; font.pixelSize: 14
                                color: Etat.cTexte
                                selectionColor: Etat.cAccent2
                            }
                            PBouton {
                                id: boutonFichier
                                visible: !!bloc.modelData.fichier
                                texte: "Ouvrir le fichier"
                                plein: true
                                onClique: Etat.lancer(["xdg-open", bloc.modelData.fichier])
                            }
                        }
                    }
                }
            }
        }

        // ── Zone de saisie ──
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(150, Math.max(52, saisie.contentHeight + 26))
            radius: 18
            color: Qt.rgba(1, 1, 1, 0.06)
            border.width: 1
            border.color: saisie.activeFocus ? Etat.cBord : Qt.rgba(154/255, 168/255, 214/255, 0.25)

            Flickable {
                id: defilSaisie
                anchors { left: parent.left; right: boutonEnvoyer.left; top: parent.top; bottom: parent.bottom; leftMargin: 18; rightMargin: 10; topMargin: 13; bottomMargin: 13 }
                contentHeight: saisie.contentHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                TextEdit {
                    id: saisie
                    width: defilSaisie.width
                    wrapMode: TextEdit.Wrap
                    font.family: Etat.police; font.pixelSize: 14
                    color: Etat.cTexte
                    selectionColor: Etat.cAccent2
                    selectByMouse: true
                    // Entrée envoie, Maj+Entrée va à la ligne
                    Keys.onReturnPressed: ev => { if (ev.modifiers & Qt.ShiftModifier) ev.accepted = false; else fenetre.envoyer(); }
                    Keys.onEnterPressed: ev => fenetre.envoyer()
                    Keys.onEscapePressed: Etat.assistantOuvert = false
                    onCursorRectangleChanged: {
                        if (cursorRectangle.y + cursorRectangle.height > defilSaisie.contentY + defilSaisie.height)
                            defilSaisie.contentY = cursorRectangle.y + cursorRectangle.height - defilSaisie.height;
                    }
                    Text {
                        visible: saisie.text === ""
                        text: Etat.modeAssistant === "cv" ? "Décris ton parcours, tes compétences…"
                            : (Etat.modeAssistant === "maquette" ? "Décris la page ou l'écran à créer…" : "Écris ta demande…")
                        font: saisie.font
                        color: Etat.cDiscret
                    }
                }
            }
            Rectangle {
                id: boutonEnvoyer
                anchors { right: parent.right; rightMargin: 8; bottom: parent.bottom; bottomMargin: 8 }
                width: 36; height: 36; radius: 18
                opacity: saisie.text.trim() !== "" && !fenetre.attente ? 1 : 0.4
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#4f8bff" }
                    GradientStop { position: 1.0; color: "#2f6bff" }
                }
                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.family: Etat.icones; font.pixelSize: 15; color: "white"
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: fenetre.envoyer() }
            }
        }

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: "Les créations sont rangées dans ~/IA/Créations · l'IA peut se tromper, vérifie ce qui compte"
            font.family: Etat.police; font.pixelSize: 11; color: Etat.cDiscret
        }
    }
}
