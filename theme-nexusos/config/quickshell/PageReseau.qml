// Paramètres › Réseau et Internet
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    spacing: 14

    PSource { id: net; sujet: "reseau"; Component.onCompleted: recharger() }
    Connections { target: Etat; function onActionParamTerminee() { net.recharger(); } }
    property var d: net.donnees || ({})
    property string choisi: ""          // réseau Wi-Fi dont on saisit le mot de passe

    function barres(signal) {
        return signal >= 70 ? "▂▄▆█" : signal >= 45 ? "▂▄▆" : signal >= 20 ? "▂▄" : "▂";
    }

    PCarte {
        titre: "État"
        visible: net.donnees !== null

        PLigne {
            visible: page.d.disponible === false
            glyphe: ""; teinte: "#f59e0b"
            titre: "NetworkManager n'est pas disponible"
            detail: "Le réglage du réseau depuis cette fenêtre a besoin de NetworkManager."
            separateur: false
        }
        Repeater {
            model: page.d.connexions || []
            PLigne {
                required property var modelData
                glyphe: modelData.type.indexOf("wireless") >= 0 ? "" : ""
                teinte: "#22c55e"
                titre: modelData.nom
                detail: (modelData.type.indexOf("wireless") >= 0 ? "Wi-Fi" : "Ethernet") + " · connecté" + (page.d.ip ? " · " + page.d.ip : "")
            }
        }
        PLigne {
            visible: page.d.disponible === true && (!page.d.connexions || page.d.connexions.length === 0)
            glyphe: ""; teinte: "#ef4444"
            titre: "Hors ligne"
            detail: "Aucune connexion active"
        }
        PLigne {
            visible: page.d.disponible === true
            glyphe: ""; teinte: "#0ea5e9"
            titre: "Wi-Fi"
            detail: page.d.wifiActif ? "Activé" : "Désactivé"
            separateur: false
            PInterrupteur {
                anchors.verticalCenter: parent.verticalCenter
                coche: !!page.d.wifiActif
                onBascule: v => Etat.agirParam(["wifi", v ? "on" : "off"])
            }
        }
    }

    PCarte {
        titre: "Réseaux Wi-Fi disponibles"
        visible: page.d.disponible === true && page.d.wifiActif === true

        Repeater {
            model: page.d.reseaux || []
            ColumnLayout {
                id: ligneWifi
                required property var modelData
                Layout.fillWidth: true
                spacing: 0
                PLigne {
                    glyphe: ""; teinte: ligneWifi.modelData.actif ? "#22c55e" : "#0ea5e9"
                    titre: ligneWifi.modelData.ssid
                    detail: (ligneWifi.modelData.actif ? "Connecté · " : "")
                          + (ligneWifi.modelData.securite && ligneWifi.modelData.securite !== "--" ? "Sécurisé" : "Ouvert")
                    valeur: page.barres(ligneWifi.modelData.signal)
                    cliquable: !ligneWifi.modelData.actif
                    onClique: page.choisi = (page.choisi === ligneWifi.modelData.ssid ? "" : ligneWifi.modelData.ssid)
                }
                RowLayout {
                    visible: page.choisi === ligneWifi.modelData.ssid
                    Layout.fillWidth: true
                    Layout.leftMargin: 66
                    Layout.rightMargin: 18
                    Layout.bottomMargin: 12
                    spacing: 10
                    PChamp {
                        id: mdp
                        Layout.fillWidth: true
                        visible: ligneWifi.modelData.securite && ligneWifi.modelData.securite !== "--"
                        motDePasse: true
                        indication: "Mot de passe du Wi-Fi"
                        onValide: t => { Etat.agirParam(["connecter", ligneWifi.modelData.ssid, t]); page.choisi = ""; }
                    }
                    PBouton {
                        texte: "Se connecter"
                        plein: true
                        onClique: { Etat.agirParam(["connecter", ligneWifi.modelData.ssid, mdp.texte]); page.choisi = ""; }
                    }
                }
            }
        }
        PLigne {
            visible: !page.d.reseaux || page.d.reseaux.length === 0
            titre: "Aucun réseau Wi-Fi trouvé"
            detail: "Dans VirtualBox, la VM passe par le réseau du PC (Ethernet) : c'est normal."
            separateur: false
        }
    }

    PCarte {
        PLigne {
            glyphe: ""; teinte: "#3b82f6"
            titre: "Actualiser"
            detail: "Rechercher à nouveau les réseaux"
            fleche: true
            onClique: net.recharger()
        }
        PLigne {
            glyphe: ""; teinte: "#64748b"
            titre: "Réglages avancés"
            detail: "Adresse IP fixe, DNS, proxy…"
            fleche: true
            separateur: false
            onClique: Etat.lancer(["sh", "-c", "command -v nm-connection-editor >/dev/null && exec nm-connection-editor || exec kitty -e nmtui"])
        }
    }
}
