// Paramètres › Mémoire et performances
// Données : nexus-param.py memoire (lui-même aidé par « nexus-veille json »), relues toutes les 3 s.
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    spacing: 14

    PSource { id: m; sujet: "memoire"; Component.onCompleted: recharger() }
    Connections { target: Etat; function onActionParamTerminee() { m.recharger(); } }
    Timer { interval: 3000; running: true; repeat: true; onTriggered: m.recharger() }
    property var d: m.donnees || ({})

    // Tailles : « 184 Mo » sous 1 Go, puis le format du thème (« 2,9 Go »)
    function mo(octets) {
        if (!octets) return "0 Mo";
        if (octets >= 1073741824) return Etat.taille(octets);
        return Math.round(octets / 1048576) + " Mo";
    }
    readonly property real total: d.ramTotale || 0
    readonly property real utilisee: total - (d.ramDisponible || 0)
    readonly property real part: total > 0 ? utilisee / total : 0
    readonly property bool tendu: part > 0.85
    readonly property var applis: d.veilleApplis || []
    readonly property var enVeille: applis.filter(a => a.enVeille)
    readonly property real compressee: enVeille.reduce((s, a) => s + (a.compressee || 0), 0)
    readonly property var delais: [ { s: 60, t: "1 min" }, { s: 120, t: "2 min" }, { s: 300, t: "5 min" },
                                    { s: 600, t: "10 min" }, { s: 900, t: "15 min" } ]

    // ── Jauge de la mémoire vive ───────────────────────────────
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: jauge.implicitHeight + 44
        radius: 18
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.rgba(6/255, 182/255, 212/255, 0.20) }
            GradientStop { position: 1.0; color: Qt.rgba(139/255, 92/255, 246/255, 0.18) }
        }
        border.width: 1
        border.color: Qt.rgba(79/255, 139/255, 1, 0.40)

        ColumnLayout {
            id: jauge
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 22 }
            spacing: 14

            RowLayout {
                spacing: 16
                PIcone { glyphe: "󰍛"; teinte: "#06b6d4"; taille: 46 }
                Column {
                    Layout.fillWidth: true
                    spacing: 4
                    Text {
                        text: page.total ? Etat.taille(page.utilisee) + " utilisés sur " + Etat.taille(page.total) : "Lecture…"
                        font.family: Etat.police; font.pixelSize: 24; font.weight: Font.DemiBold
                        color: Etat.cTexte
                    }
                    Text {
                        text: page.total ? Math.round(page.part * 100) + " % de la mémoire vive · "
                                           + Etat.taille(page.d.ramDisponible) + " disponibles" : ""
                        font.family: Etat.police; font.pixelSize: 13
                        color: page.tendu ? "#fdba74" : Etat.cDiscret
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 12; radius: 6
                color: Qt.rgba(154/255, 168/255, 214/255, 0.25)
                Rectangle {
                    width: parent.width * Math.min(1, page.part)
                    height: parent.height; radius: 6
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: page.tendu ? "#f97316" : "#4f8bff" }
                        GradientStop { position: 1.0; color: page.tendu ? "#ef4444" : "#8b5cf6" }
                    }
                    Behavior on width { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
                }
            }

            Text {
                text: "Mémoire d'échange : " + page.mo((page.d.swapTotal || 0) - (page.d.swapLibre || 0))
                      + " utilisés sur " + Etat.taille(page.d.swapTotal)
                      + (page.compressee > 0 ? " · la veille a compressé " + page.mo(page.compressee) : "")
                font.family: Etat.police; font.pixelSize: 12
                color: Etat.cDiscret
            }
        }
    }

    // ── Veille compressée ──────────────────────────────────────
    PCarte {
        titre: "Veille compressée"
        PLigne {
            glyphe: "󰜗"; teinte: "#06b6d4"
            titre: "Veille des applis hors écran"
            detail: !page.d.veilleInstallee ? "Non installée (phase 6b)"
                  : page.d.veilleActive ? "Une appli cachée depuis un moment est gelée et compressée ; elle se réveille dès que tu reviens dessus"
                  : "Désactivée — aucune appli n'est mise en veille"
            PInterrupteur {
                anchors.verticalCenter: parent.verticalCenter
                coche: !!page.d.veilleActive
                actif: !!page.d.veilleInstallee
                onBascule: v => Etat.agirParam(["veille", v ? "on" : "off"])
            }
        }
        PLigne {
            glyphe: "󰔛"; teinte: "#8b5cf6"
            titre: "Délai avant la mise en veille"
            detail: "Temps passé hors écran avant de geler une appli"
            Repeater {
                model: page.delais
                PBouton {
                    required property var modelData
                    anchors.verticalCenter: parent.verticalCenter
                    texte: modelData.t
                    plein: page.d.veilleDelai === modelData.s
                    actif: !!page.d.veilleInstallee
                    onClique: Etat.agirParam(["veille-delai", String(modelData.s)])
                }
            }
        }
        PLigne {
            glyphe: "󰒲"; teinte: "#64748b"
            titre: "Applis en veille"
            detail: page.enVeille.length === 0 ? "Aucune pour le moment"
                  : page.enVeille.length + " appli(s) · " + page.mo(page.compressee) + " compressés"
            separateur: false
            PBouton {
                anchors.verticalCenter: parent.verticalCenter
                texte: "Tout réveiller"
                actif: page.enVeille.length > 0
                onClique: Etat.agirParam(["veille-reveiller"])
            }
        }
    }

    PCarte {
        titre: "Applis surveillées"
        visible: page.applis.length > 0
        Repeater {
            model: page.applis
            PLigne {
                required property var modelData
                required property int index
                glyphe: modelData.enVeille ? "󰒲" : "󰄨"
                teinte: modelData.enVeille ? "#06b6d4" : "#22c55e"
                titre: modelData.appli
                detail: modelData.enVeille
                        ? "En veille · " + page.mo(modelData.compressee) + " compressés"
                        : "Active"
                valeur: page.mo(modelData.ram)
                separateur: index < page.applis.length - 1
            }
        }
    }

    // ── Applis gourmandes ──────────────────────────────────────
    PCarte {
        titre: "Programmes qui utilisent le plus de mémoire"
        Repeater {
            model: page.d.gourmandes || []
            PLigne {
                required property var modelData
                required property int index
                glyphe: "󰈸"; teinte: index === 0 ? "#ef4444" : "#f97316"
                titre: modelData.nom
                valeur: page.mo(modelData.ram)
                separateur: index < (page.d.gourmandes || []).length - 1
            }
        }
    }

    // ── Protection ─────────────────────────────────────────────
    PCarte {
        titre: "Protection"
        PLigne {
            glyphe: "󰕥"; teinte: "#22c55e"
            titre: "Anti-gel (earlyoom)"
            detail: "Si la mémoire est pleine, ferme d'abord le navigateur au lieu de laisser tout le système se figer"
            PInterrupteur {
                anchors.verticalCenter: parent.verticalCenter
                coche: !!page.d.earlyoom
                onBascule: v => Etat.agirParam(["earlyoom", v ? "on" : "off"])
            }
        }
        PLigne {
            glyphe: "󰗄"; teinte: "#3b82f6"
            titre: "Compression zram"
            detail: !page.d.zramActif ? "Inactive"
                  : page.d.zram && page.d.zram.donnees > 1048576
                    ? page.mo(page.d.zram.donnees) + " de données rangées dans " + page.mo(page.d.zram.occupe)
                      + " de RAM (×" + (page.d.zram.donnees / Math.max(1, page.d.zram.occupe)).toFixed(1).replace(".", ",") + ")"
                    : "Prête — rien à compresser pour l'instant"
            valeur: page.d.zramActif ? "Activée" : "Désactivée"
            separateur: false
        }
    }
}
