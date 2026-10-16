// Paramètres › Accueil : résumé du PC et réglages rapides
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    spacing: 14

    PSource { id: infos; sujet: "infos"; Component.onCompleted: recharger() }
    PSource { id: reseau; sujet: "reseau"; Component.onCompleted: recharger() }
    PSource { id: son; sujet: "son"; Component.onCompleted: recharger() }
    PSource { id: bt; sujet: "bluetooth"; Component.onCompleted: recharger() }
    PSource { id: notifs; sujet: "notifications"; Component.onCompleted: recharger() }
    Connections {
        target: Etat
        function onActionParamTerminee() { infos.recharger(); reseau.recharger(); son.recharger(); bt.recharger(); notifs.recharger(); }
    }

    property var i: infos.donnees || ({})
    property bool renommage: false

    // Carte du PC
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 112
        radius: 18
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.rgba(47/255, 107/255, 1, 0.28) }
            GradientStop { position: 1.0; color: Qt.rgba(139/255, 92/255, 246/255, 0.20) }
        }
        border.width: 1
        border.color: Qt.rgba(79/255, 139/255, 1, 0.40)

        RowLayout {
            anchors { fill: parent; leftMargin: 22; rightMargin: 22 }
            spacing: 18
            Image {
                Layout.preferredWidth: 76; Layout.preferredHeight: 76
                sourceSize: Qt.size(152, 152)
                source: Etat.logo
            }
            Column {
                Layout.fillWidth: true
                spacing: 4
                Text {
                    visible: !page.renommage
                    text: page.i.hote || "…"
                    font.family: Etat.police; font.pixelSize: 21; font.weight: Font.DemiBold
                    color: Etat.cTexte
                }
                PChamp {
                    id: champNom
                    visible: page.renommage
                    width: 260
                    indication: "Nouveau nom du PC"
                    onValide: t => { Etat.agirParam(["hote", t]); page.renommage = false; }
                }
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: [page.i.modele, (page.i.processeur || "").replace(/ with .*| \d+-Core.*/,""), page.i.ramTotale ? Etat.taille(page.i.ramTotale) + " de RAM" : ""].filter(x => x).join("  ·  ")
                    font.family: Etat.police; font.pixelSize: 13
                    color: Etat.cDiscret
                }
            }
            PBouton {
                texte: page.renommage ? "Valider" : "Renommer"
                plein: page.renommage
                onClique: {
                    if (page.renommage) { Etat.agirParam(["hote", champNom.texte]); page.renommage = false; }
                    else { champNom.texte = page.i.hote || ""; page.renommage = true; champNom.focaliser(); }
                }
            }
        }
    }

    // Trois résumés cliquables
    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        Repeater {
            model: [
                { page: "reseau", glyphe: "", teinte: "#22c55e",
                  titre: page.etatReseau(), detail: page.detailReseau() },
                { page: "maj", glyphe: "", teinte: "#3b82f6",
                  titre: "Mises à jour", detail: "Dernière : " + Etat.depuis(page.i.derniereMaj) },
                { page: "maj", glyphe: "", teinte: "#f59e0b",
                  titre: Etat.taille(page.i.disqueUtilise) + " / " + Etat.taille(page.i.disqueTotal),
                  detail: (page.i.snapshots || 0) + " snapshots de sécurité" }
            ]
            Rectangle {
                id: tuile
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 70
                radius: 14
                color: zoneTuile.containsMouse ? Qt.rgba(79/255, 139/255, 1, 0.12) : Qt.rgba(1, 1, 1, 0.04)
                border.width: 1
                border.color: Qt.rgba(154/255, 168/255, 214/255, 0.18)
                Row {
                    anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                    spacing: 12
                    PIcone { glyphe: tuile.modelData.glyphe; teinte: tuile.modelData.teinte; taille: 34; anchors.verticalCenter: parent.verticalCenter }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Text { text: tuile.modelData.titre; font.family: Etat.police; font.pixelSize: 13; font.weight: Font.DemiBold; color: Etat.cTexte }
                        Text { text: tuile.modelData.detail; font.family: Etat.police; font.pixelSize: 11; color: Etat.cDiscret }
                    }
                }
                MouseArea {
                    id: zoneTuile
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Etat.pageParametres = tuile.modelData.page
                }
            }
        }
    }

    function etatReseau() {
        const r = reseau.donnees;
        if (!r) return "Réseau…";
        return r.connexions && r.connexions.length > 0 ? "Connecté" : "Hors ligne";
    }
    function detailReseau() {
        const r = reseau.donnees;
        if (!r || !r.connexions || r.connexions.length === 0) return "Aucune connexion";
        const c = r.connexions[0];
        return (c.type.indexOf("wireless") >= 0 ? "Wi-Fi · " : "Ethernet · ") + c.nom;
    }

    // Réglages rapides
    PCarte {
        titre: "Réglages rapides"

        PLigne {
            glyphe: ""; teinte: "#ec4899"
            titre: "Volume"
            detail: son.donnees && son.donnees.muet ? "Son coupé" : ""
            PCurseur {
                width: 260
                anchors.verticalCenter: parent.verticalCenter
                valeur: son.donnees ? Math.max(0, son.donnees.volume) : 0
                onRelache: v => Etat.agirParam(["volume", String(v)])
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 44
                horizontalAlignment: Text.AlignRight
                text: son.donnees && son.donnees.volume >= 0 ? son.donnees.volume + " %" : "—"
                font.family: Etat.police; font.pixelSize: 13; color: Etat.cTexte
            }
        }
        PLigne {
            visible: reseau.donnees && reseau.donnees.disponible
            glyphe: ""; teinte: "#0ea5e9"
            titre: "Wi-Fi"
            detail: reseau.donnees && reseau.donnees.wifiActif ? "Activé" : "Désactivé"
            PInterrupteur {
                anchors.verticalCenter: parent.verticalCenter
                coche: !!(reseau.donnees && reseau.donnees.wifiActif)
                onBascule: v => Etat.agirParam(["wifi", v ? "on" : "off"])
            }
        }
        PLigne {
            visible: bt.donnees && bt.donnees.adaptateur
            glyphe: ""; teinte: "#2f6bff"
            titre: "Bluetooth"
            detail: bt.donnees && bt.donnees.allume ? "Activé" : "Désactivé"
            PInterrupteur {
                anchors.verticalCenter: parent.verticalCenter
                coche: !!(bt.donnees && bt.donnees.allume)
                onBascule: v => Etat.agirParam(["bluetooth-etat", v ? "on" : "off"])
            }
        }
        PLigne {
            glyphe: ""; teinte: "#ef4444"
            titre: "Ne pas déranger"
            detail: "Masque les notifications"
            separateur: false
            PInterrupteur {
                anchors.verticalCenter: parent.verticalCenter
                coche: !!(notifs.donnees && notifs.donnees.nePasDeranger)
                onBascule: v => Etat.agirParam(["nepasderanger", v ? "on" : "off"])
            }
        }
    }
}
