// Paramètres › Applications : toutes les applications, épinglage dans la barre et le menu
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    spacing: 14
    property string filtre: ""

    property var applis: {
        const vals = DesktopEntries.applications.values;
        const res = [];
        const q = filtre.trim().toLowerCase();
        for (let i = 0; i < vals.length; i++) {
            const e = vals[i];
            if (!Etat.visible(e)) continue;
            if (q !== "" && e.name.toLowerCase().indexOf(q) < 0) continue;
            res.push(e);
        }
        res.sort((a, b) => a.name.localeCompare(b.name, "fr"));
        return res;
    }

    function basculer(cible, id, valeur) {
        const actuelle = (cible === "barre" ? Etat.listeBarre : Etat.listeMenu).slice();
        const i = actuelle.indexOf(id);
        if (valeur && i < 0) actuelle.push(id);
        if (!valeur && i >= 0) actuelle.splice(i, 1);
        Etat.enregistrerEpingles(cible, actuelle);
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 12
        PChamp {
            Layout.fillWidth: true
            indication: "Rechercher une application"
            onTexteChanged: page.filtre = texte
        }
        Text {
            text: page.applis.length + " applications"
            font.family: Etat.police; font.pixelSize: 12; color: Etat.cDiscret
        }
    }

    Text {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: "« Barre » : visible dans la barre du bas.  « Menu » : dans la section Épinglé du menu Démarrer (12 au maximum)."
        font.family: Etat.police; font.pixelSize: 12; color: Etat.cDiscret
    }

    PCarte {
        Repeater {
            model: page.applis
            Item {
                id: ligne
                required property var modelData
                required property int index
                Layout.fillWidth: true
                implicitHeight: 58
                property bool dansBarre: Etat.listeBarre.indexOf(modelData.id) >= 0
                property bool dansMenu: Etat.listeMenu.indexOf(modelData.id) >= 0

                RowLayout {
                    anchors { fill: parent; leftMargin: 20; rightMargin: 18 }
                    spacing: 14
                    IconImage {
                        implicitSize: 32
                        source: Quickshell.iconPath(ligne.modelData.icon, "application-x-executable")
                    }
                    Column {
                        Layout.fillWidth: true
                        Text {
                            width: parent.width; elide: Text.ElideRight
                            text: ligne.modelData.name
                            font.family: Etat.police; font.pixelSize: 14; font.weight: Font.DemiBold; color: Etat.cTexte
                        }
                        Text {
                            width: parent.width; elide: Text.ElideRight
                            visible: text !== ""
                            text: ligne.modelData.genericName || ligne.modelData.comment || ""
                            font.family: Etat.police; font.pixelSize: 11; color: Etat.cDiscret
                        }
                    }
                    Text { text: "Barre"; font.family: Etat.police; font.pixelSize: 12; color: Etat.cDiscret }
                    PInterrupteur {
                        coche: ligne.dansBarre
                        onBascule: v => page.basculer("barre", ligne.modelData.id, v)
                    }
                    Text { text: "Menu"; font.family: Etat.police; font.pixelSize: 12; color: Etat.cDiscret; Layout.leftMargin: 8 }
                    PInterrupteur {
                        coche: ligne.dansMenu
                        onBascule: v => page.basculer("menu", ligne.modelData.id, v)
                    }
                    PBouton {
                        Layout.leftMargin: 8
                        texte: "Ouvrir"
                        onClique: ligne.modelData.execute()
                    }
                }
                Rectangle {
                    visible: ligne.index < page.applis.length - 1
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 66; rightMargin: 18 }
                    height: 1
                    color: Qt.rgba(154/255, 168/255, 214/255, 0.10)
                }
            }
        }
    }

    PCarte {
        PLigne {
            glyphe: ""; teinte: "#22c55e"
            titre: "Installer des applications"
            detail: "Navigateur, bureautique, Discord, Spotify… arrivent avec la phase 6 de NexusOS."
            separateur: false
        }
    }
}
