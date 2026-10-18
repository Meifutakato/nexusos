// NexusOS — fenêtre Paramètres (organisation par groupes, façon HyperOS)
// Ouverture : menu Démarrer › Paramètres, icône du bureau, ou
//   quickshell ipc call parametres ouvrir        (page d'accueil)
//   quickshell ipc call parametres page son       (une page précise)
import Quickshell
import QtQuick
import QtQuick.Layouts

FloatingWindow {
    id: fenetre
    title: "Paramètres NexusOS"
    visible: Etat.parametresOuverts
    implicitWidth: 1180
    implicitHeight: 860
    color: "#0a1230"

    property string page: "accueil"
    property string recherche: ""

    onVisibleChanged: {
        if (visible) { page = Etat.pageParametres; recherche = ""; }
        else Etat.parametresOuverts = false;
    }
    Connections {
        target: Etat
        function onPageParametresChanged() { fenetre.page = Etat.pageParametres; }
    }

    // ── Organisation : un tableau par groupe (cartes séparées dans la colonne) ──
    readonly property var groupesTheme: [
        [ { id: "accueil",      titre: "Accueil",                       glyphe: "", teinte: "#2f6bff" } ],
        [ { id: "bluetooth",    titre: "Bluetooth et appareils",        glyphe: "", teinte: "#2f6bff" },
          { id: "reseau",       titre: "Réseau et Internet",            glyphe: "", teinte: "#0ea5e9" },
          { id: "options",      titre: "Plus d'options de connexion",   glyphe: "", teinte: "#64748b" } ],
        [ { id: "applications", titre: "Applications",                  glyphe: "", teinte: "#8b5cf6" },
          { id: "jeux",         titre: "Jeux",                          glyphe: "", teinte: "#a855f7" } ],
        [ { id: "ecran",        titre: "Écran",                         glyphe: "", teinte: "#0ea5e9" },
          { id: "son",          titre: "Son",                           glyphe: "", teinte: "#ec4899" },
          { id: "notifications",titre: "Notifications",                 glyphe: "", teinte: "#ef4444" },
          { id: "fond",         titre: "Fond d'écran et thème",         glyphe: "", teinte: "#f59e0b" } ],
        [ { id: "comptes",      titre: "Comptes",                       glyphe: "", teinte: "#f97316" },
          { id: "heure",        titre: "Heure et langue",               glyphe: "", teinte: "#14b8a6" },
          { id: "securite",     titre: "Sécurité et confidentialité",   glyphe: "", teinte: "#22c55e" },
          { id: "batterie",     titre: "Batterie",                      glyphe: "", teinte: "#84cc16" } ],
        [ { id: "memoire",      titre: "Mémoire et performances",       glyphe: "\udb80\udf5b", teinte: "#06b6d4" },
          { id: "maj",          titre: "Mise à jour et sauvegarde",     glyphe: "", teinte: "#3b82f6" },
          { id: "apropos",      titre: "À propos de NexusOS",           glyphe: "", teinte: "#64748b" } ]
    ]
    // Groupe du module IA (ia-nexusos), seulement s'il est installé ; ses pages sont dans ~/.config/quickshell/ia/
    readonly property var groupeIa: [
        { id: "assistant",    titre: "Assistant IA",  glyphe: "\udb81\ude74", teinte: "#ec4899" },
        { id: "ialocales",    titre: "IA locales",    glyphe: "\uf2db", teinte: "#22c55e" },
        { id: "iaenligne",    titre: "IA en ligne",   glyphe: "\uf0c2", teinte: "#3b82f6" },
        { id: "agents",       titre: "Agents IA",     glyphe: "\udb81\udea9", teinte: "#14b8a6" }
    ]
    readonly property var pagesIa: ({
        assistant: "PageAssistant.qml", ialocales: "PageIaLocales.qml", iaenligne: "PageIaEnLigne.qml", agents: "PageAgents.qml"
    })
    readonly property var groupes: Etat.iaInstalle
        ? groupesTheme.slice(0, 3).concat([groupeIa], groupesTheme.slice(3))
        : groupesTheme
    function chargerPage() {
        if (pagesIa[page] && Etat.iaInstalle) chargeur.setSource(Qt.resolvedUrl("ia/" + pagesIa[page]), {});
        else chargeur.sourceComponent = pages[page] || pageAccueil;
    }
    onPageChanged: chargerPage()
    Component.onCompleted: chargerPage()

    readonly property var pages: ({
        accueil: pageAccueil, bluetooth: pageBluetooth, reseau: pageReseau, options: pageOptions,
        applications: pageApplications, jeux: pageJeux, ecran: pageEcran, son: pageSon,
        notifications: pageNotifications, fond: pageFond, comptes: pageComptes, heure: pageHeure,
        securite: pageSecurite, batterie: pageBatterie, memoire: pageMemoire, maj: pageMaj, apropos: pageAPropos
    })
    function titreDe(id) {
        for (let g = 0; g < groupes.length; g++)
            for (let i = 0; i < groupes[g].length; i++)
                if (groupes[g][i].id === id) return groupes[g][i].titre;
        return "";
    }
    function correspond(entree) {
        const q = recherche.trim().toLowerCase();
        return q === "" || entree.titre.toLowerCase().indexOf(q) >= 0;
    }

    Component { id: pageAccueil;       PageAccueil {} }
    Component { id: pageBluetooth;     PageBluetooth {} }
    Component { id: pageReseau;        PageReseau {} }
    Component { id: pageOptions;       PageOptions {} }
    Component { id: pageApplications;  PageApplications {} }
    Component { id: pageJeux;          PageJeux {} }
    Component { id: pageEcran;         PageEcran {} }
    Component { id: pageSon;           PageSon {} }
    Component { id: pageNotifications; PageNotifications {} }
    Component { id: pageFond;          PageFond {} }
    Component { id: pageComptes;       PageComptes {} }
    Component { id: pageHeure;         PageHeure {} }
    Component { id: pageSecurite;      PageSecurite {} }
    Component { id: pageBatterie;      PageBatterie {} }
    Component { id: pageMemoire;       PageMemoire {} }
    Component { id: pageMaj;           PageMaj {} }
    Component { id: pageAPropos;       PageAPropos {} }

    // ── Fond : dégradé sombre aux couleurs du thème ─────────────
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0b1538" }
            GradientStop { position: 1.0; color: "#070d26" }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ── Colonne de gauche ───────────────────────────────────
        Rectangle {
            Layout.preferredWidth: 320
            Layout.fillHeight: true
            color: Qt.rgba(1, 1, 1, 0.025)

            Rectangle {
                anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                width: 1
                color: Qt.rgba(154/255, 168/255, 214/255, 0.15)
            }

            ColumnLayout {
                anchors { fill: parent; margins: 16 }
                spacing: 12

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 6
                    text: "Paramètres"
                    font.family: Etat.police
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                    color: Etat.cTexte
                }

                // Recherche dans les catégories
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    radius: 19
                    color: Qt.rgba(1, 1, 1, 0.06)
                    border.width: 1
                    border.color: champRecherche.activeFocus ? Etat.cBord : Qt.rgba(154/255, 168/255, 214/255, 0.25)
                    Text {
                        id: loupe
                        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                        text: ""
                        font.family: Etat.icones
                        font.pixelSize: 14
                        color: Etat.cDiscret
                    }
                    TextInput {
                        id: champRecherche
                        anchors { left: loupe.right; leftMargin: 10; right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                        font.family: Etat.police
                        font.pixelSize: 13
                        color: Etat.cTexte
                        clip: true
                        onTextChanged: fenetre.recherche = text
                        Text {
                            visible: champRecherche.text === ""
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Rechercher un paramètre"
                            font: champRecherche.font
                            color: Etat.cDiscret
                        }
                    }
                }

                // Groupes de catégories
                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: colonneGroupes.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: colonneGroupes
                        width: parent.width
                        spacing: 8

                        Repeater {
                            model: fenetre.groupes
                            Rectangle {
                                id: groupe
                                required property var modelData
                                property int visibles: {
                                    let n = 0;
                                    for (let i = 0; i < modelData.length; i++) if (fenetre.correspond(modelData[i])) n++;
                                    return n;
                                }
                                visible: visibles > 0
                                width: colonneGroupes.width
                                height: colonneEntrees.implicitHeight + 6
                                radius: 16
                                color: Qt.rgba(1, 1, 1, 0.045)
                                border.width: 1
                                border.color: Qt.rgba(154/255, 168/255, 214/255, 0.12)

                                Column {
                                    id: colonneEntrees
                                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 3 }
                                    Repeater {
                                        model: groupe.modelData
                                        Rectangle {
                                            id: entree
                                            required property var modelData
                                            property bool choisie: fenetre.page === modelData.id
                                            visible: fenetre.correspond(modelData)
                                            width: colonneEntrees.width
                                            height: visible ? 40 : 0
                                            radius: 12
                                            color: choisie ? Qt.rgba(47/255, 107/255, 1, 0.24)
                                                 : (zoneEntree.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")
                                            Behavior on color { ColorAnimation { duration: 110 } }
                                            Rectangle {
                                                visible: entree.choisie
                                                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                                                width: 3; height: 22; radius: 2
                                                color: Etat.cAccent
                                            }
                                            Row {
                                                anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                                                spacing: 14
                                                PIcone { glyphe: entree.modelData.glyphe; teinte: entree.modelData.teinte; taille: 26 }
                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: entree.modelData.titre
                                                    font.family: Etat.police
                                                    font.pixelSize: 14
                                                    color: Etat.cTexte
                                                }
                                            }
                                            MouseArea {
                                                id: zoneEntree
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: fenetre.page = entree.modelData.id
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Partie droite : la page choisie ─────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Text {
                id: titrePage
                anchors { left: parent.left; top: parent.top; leftMargin: 36; topMargin: 26 }
                text: fenetre.titreDe(fenetre.page)
                font.family: Etat.police
                font.pixelSize: 28
                font.weight: Font.DemiBold
                color: Etat.cTexte
            }

            Flickable {
                id: defilement
                anchors { left: parent.left; right: parent.right; top: titrePage.bottom; bottom: parent.bottom; topMargin: 18 }
                contentHeight: chargeur.item ? chargeur.item.implicitHeight + 40 : 0
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Loader {
                    id: chargeur
                    x: 36
                    width: defilement.width - 72
                    onLoaded: defilement.contentY = 0
                    onItemChanged: if (item) item.width = Qt.binding(() => chargeur.width)
                }
            }
        }
    }

    // ── Message en bas (résultat d'une action) ──────────────────
    Rectangle {
        id: bulle
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 24 }
        width: texteBulle.implicitWidth + 40
        height: 42
        radius: 21
        color: Etat.messageOk ? Qt.rgba(20/255, 32/255, 72/255, 0.97) : Qt.rgba(80/255, 20/255, 30/255, 0.97)
        border.width: 1
        border.color: Etat.messageOk ? Etat.cBord : Qt.rgba(1, 0.42, 0.42, 0.7)
        opacity: 0
        visible: opacity > 0
        Text {
            id: texteBulle
            anchors.centerIn: parent
            text: Etat.messageParam
            font.family: Etat.police
            font.pixelSize: 13
            color: Etat.cTexte
        }
        SequentialAnimation {
            id: animBulle
            NumberAnimation { target: bulle; property: "opacity"; to: 1; duration: 150 }
            PauseAnimation { duration: 2600 }
            NumberAnimation { target: bulle; property: "opacity"; to: 0; duration: 300 }
        }
        Connections {
            target: Etat
            function onNumeroMessageChanged() { if (fenetre.visible) animBulle.restart(); }
        }
    }
}
