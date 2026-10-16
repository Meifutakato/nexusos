// Paramètres › À propos de NexusOS
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    spacing: 14

    PSource { id: infos; sujet: "infos"; Component.onCompleted: recharger() }
    property var d: infos.donnees || ({})
    function duree(s) {
        const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60);
        return h > 0 ? h + " h " + m + " min" : m + " min";
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 170
        radius: 18
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.rgba(47/255, 107/255, 1, 0.25) }
            GradientStop { position: 1.0; color: Qt.rgba(139/255, 92/255, 246/255, 0.18) }
        }
        border.width: 1
        border.color: Qt.rgba(79/255, 139/255, 1, 0.40)
        Row {
            anchors.centerIn: parent
            spacing: 26
            Image { width: 120; height: 120; sourceSize: Qt.size(240, 240); source: Etat.logo }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                Text { text: "NexusOS"; font.family: Etat.police; font.pixelSize: 34; font.weight: Font.DemiBold; color: Etat.cTexte }
                Text { text: "Version de développement · base Arch Linux"; font.family: Etat.police; font.pixelSize: 14; color: Etat.cDiscret }
                Text { text: "Bureau Hyprland · interface Quickshell"; font.family: Etat.police; font.pixelSize: 14; color: Etat.cDiscret }
            }
        }
    }

    PCarte {
        titre: "Cet appareil"
        PLigne { glyphe: ""; teinte: "#0ea5e9"; titre: "Nom du PC"; valeur: page.d.hote || "—" }
        PLigne { glyphe: ""; teinte: "#8b5cf6"; titre: "Processeur"; detail: (page.d.processeur || "—") + (page.d.coeurs ? " · " + page.d.coeurs + " cœurs" : "") }
        PLigne { glyphe: ""; teinte: "#ec4899"; titre: "Carte graphique"; detail: page.d.gpu || "—" }
        PLigne { glyphe: ""; teinte: "#22c55e"; titre: "Mémoire (RAM)"; valeur: Etat.taille(page.d.ramUtilisee) + " utilisés sur " + Etat.taille(page.d.ramTotale) }
        PLigne { glyphe: ""; teinte: "#f59e0b"; titre: "Stockage"; valeur: Etat.taille(page.d.disqueUtilise) + " sur " + Etat.taille(page.d.disqueTotal) }
        PLigne { glyphe: ""; teinte: "#64748b"; titre: "Noyau Linux"; valeur: page.d.noyau || "—" }
        PLigne { glyphe: ""; teinte: "#14b8a6"; titre: "Allumé depuis"; valeur: page.d.allumeDepuis ? page.duree(page.d.allumeDepuis) : "—"; separateur: false }
    }

    PCarte {
        PLigne {
            glyphe: ""; teinte: "#2f6bff"
            titre: "Infos système détaillées"
            detail: "Ouvre la fiche NexusOS dans le terminal"
            fleche: true
            separateur: false
            onClique: Etat.lancer(["kitty", "--hold", "fastfetch"])
        }
    }
}
