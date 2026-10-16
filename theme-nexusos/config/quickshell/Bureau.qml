// NexusOS — icônes du bureau (colonne de gauche, sous les fenêtres)
// Double-clic pour ouvrir, comme sous Windows.
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick

PanelWindow {
    id: bureau
    required property var modelData
    screen: modelData

    WlrLayershell.layer: WlrLayer.Bottom      // au-dessus du fond d'écran, sous les fenêtres
    WlrLayershell.namespace: "nexus-bureau"
    exclusiveZone: 0                           // ne pousse pas les fenêtres
    anchors { top: true; left: true; bottom: true }
    margins { top: 6; left: 6 }
    implicitWidth: 104
    color: "transparent"

    property int selection: -1

    function ouvrirDossier(chemin) {
        Etat.lancer(["sh", "-c", 'thunar "$1"', "sh", chemin]);
    }

    // ── Les icônes : modifier cette liste pour en ajouter ou en retirer ──
    property var icones: [
        { nom: "Ce PC",          icone: "computer",           action: "pc" },
        { nom: "Corbeille",      icone: "user-trash",         action: "corbeille" },
        { nom: "Dossiers perso", icone: "folder-blue",        action: "perso" },
        { nom: "Cloud",          icone: "folder-cloud",       action: "cloud" },
        { nom: "Paramètres",     icone: "preferences-system", action: "parametres" },
        { nom: "NexusOS",        icone: "",                   action: "nexusos" },
        { nom: "Jeux",           icone: "applications-games", action: "jeux" },
        { nom: "Applications",   icone: "view-app-grid",      action: "applications" }
    ]

    function agir(action) {
        if (action === "pc") ouvrirDossier("/");
        else if (action === "corbeille") ouvrirDossier("trash:///");
        else if (action === "perso") ouvrirDossier(Quickshell.env("HOME"));
        else if (action === "cloud") Etat.bientot("Le Cloud NexusOS");
        else if (action === "parametres") Etat.bientot("Les Paramètres NexusOS");
        else if (action === "nexusos") Etat.lancer(["kitty", "--hold", "fastfetch"]);
        else if (action === "jeux") Etat.ouvrirMenuSur("categorie", "Game", "Jeux");
        else if (action === "applications") Etat.ouvrirMenuSur("applications");
    }

    // Un clic sur le vide enlève la sélection
    MouseArea {
        anchors.fill: parent
        onClicked: bureau.selection = -1
    }

    Column {
        anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
        spacing: 6

        Repeater {
            model: bureau.icones

            Item {
                id: icone
                required property var modelData
                required property int index
                width: 92; height: 88
                property bool choisie: bureau.selection === index

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: icone.choisie ? Qt.rgba(79/255, 139/255, 1, 0.30)
                         : (zoneIcone.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
                    border.width: icone.choisie ? 1 : 0
                    border.color: Qt.rgba(79/255, 139/255, 1, 0.7)
                    Behavior on color { ColorAnimation { duration: 110 } }
                }

                // Icône du thème Papirus, ou logo NexusOS
                IconImage {
                    id: image
                    visible: icone.modelData.icone !== ""
                    anchors { top: parent.top; topMargin: 8; horizontalCenter: parent.horizontalCenter }
                    implicitSize: 46
                    source: icone.modelData.icone !== "" ? Quickshell.iconPath(icone.modelData.icone, "folder") : ""
                    scale: zoneIcone.pressed ? 0.92 : 1
                    Behavior on scale { NumberAnimation { duration: 90 } }
                }
                Image {
                    visible: icone.modelData.icone === ""
                    anchors { top: parent.top; topMargin: 8; horizontalCenter: parent.horizontalCenter }
                    width: 46; height: 46
                    sourceSize: Qt.size(92, 92)
                    source: Etat.logo
                    scale: zoneIcone.pressed ? 0.92 : 1
                    Behavior on scale { NumberAnimation { duration: 90 } }
                }

                // Nom avec une ombre pour rester lisible sur le fond
                Text {
                    anchors { bottom: parent.bottom; bottomMargin: 7; horizontalCenter: parent.horizontalCenter; horizontalCenterOffset: 1 }
                    text: icone.modelData.nom
                    font.family: Etat.police
                    font.pixelSize: 12
                    color: Qt.rgba(0, 0, 0, 0.7)
                }
                Text {
                    anchors { bottom: parent.bottom; bottomMargin: 8; horizontalCenter: parent.horizontalCenter }
                    text: icone.modelData.nom
                    font.family: Etat.police
                    font.pixelSize: 12
                    color: Etat.cTexte
                }

                MouseArea {
                    id: zoneIcone
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: bureau.selection = icone.index
                    onDoubleClicked: {
                        bureau.selection = -1;
                        bureau.agir(icone.modelData.action);
                    }
                }
            }
        }
    }
}
