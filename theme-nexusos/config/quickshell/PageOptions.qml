// Paramètres › Plus d'options de connexion : VPN, partage de connexion, accès à distance (SSH)
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    spacing: 14

    PSource { id: opt; sujet: "options"; Component.onCompleted: recharger() }
    Connections { target: Etat; function onActionParamTerminee() { opt.recharger(); } }
    property var d: opt.donnees || ({})
    property bool saisiePartage: false

    PCarte {
        titre: "VPN"
        Repeater {
            model: page.d.vpn || []
            PLigne {
                required property var modelData
                glyphe: ""; teinte: modelData.actif ? "#22c55e" : "#64748b"
                titre: modelData.nom
                detail: (modelData.type === "wireguard" ? "WireGuard" : "VPN") + (modelData.actif ? " · connecté" : "")
                PInterrupteur {
                    anchors.verticalCenter: parent.verticalCenter
                    coche: modelData.actif
                    onBascule: v => Etat.agirParam(["vpn", modelData.nom, v ? "on" : "off"])
                }
            }
        }
        PLigne {
            visible: !page.d.vpn || page.d.vpn.length === 0
            glyphe: ""; teinte: "#64748b"
            titre: "Aucun VPN configuré"
            detail: "Ajoute un VPN (fichier .ovpn ou WireGuard) dans les réglages avancés."
            fleche: true
            separateur: false
            onClique: Etat.lancer(["sh", "-c", "command -v nm-connection-editor >/dev/null && exec nm-connection-editor || exec kitty -e nmtui"])
        }
    }

    PCarte {
        titre: "Partage de connexion"
        PLigne {
            glyphe: ""; teinte: "#0ea5e9"
            titre: "Point d'accès Wi-Fi « NexusOS »"
            detail: page.d.partage ? "Activé — d'autres appareils peuvent se connecter" : "Partage la connexion de ce PC (il faut une carte Wi-Fi)"
            separateur: !page.saisiePartage
            PInterrupteur {
                anchors.verticalCenter: parent.verticalCenter
                coche: !!page.d.partage || page.saisiePartage
                onBascule: v => {
                    if (v) page.saisiePartage = true;
                    else { page.saisiePartage = false; Etat.agirParam(["partage", "off"]); }
                }
            }
        }
        RowLayout {
            visible: page.saisiePartage
            Layout.fillWidth: true
            Layout.leftMargin: 66; Layout.rightMargin: 18; Layout.bottomMargin: 12
            spacing: 10
            PChamp { id: mdpPartage; Layout.fillWidth: true; motDePasse: true; indication: "Mot de passe (8 caractères minimum)" }
            PBouton {
                texte: "Activer"; plein: true
                onClique: { Etat.agirParam(["partage", "on", mdpPartage.texte]); page.saisiePartage = false; }
            }
        }
    }

    PCarte {
        titre: "Accès à distance"
        PLigne {
            glyphe: ""; teinte: "#14b8a6"
            titre: "SSH"
            detail: page.d.ssh ? "Actif — connexion possible depuis Windows (ssh -p 2022 " + Quickshell.env("USER") + "@127.0.0.1)"
                               : "Désactivé"
            separateur: false
            PInterrupteur {
                anchors.verticalCenter: parent.verticalCenter
                coche: !!page.d.ssh
                onBascule: v => Etat.agirParam(["ssh", v ? "on" : "off"])
            }
        }
    }

    Text {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: "Les réglages qui touchent au système (SSH) demandent ton mot de passe dans une petite fenêtre."
        font.family: Etat.police; font.pixelSize: 12; color: Etat.cDiscret
    }
}
