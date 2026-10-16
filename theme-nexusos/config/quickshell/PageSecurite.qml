// Paramètres › Sécurité et confidentialité
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    spacing: 14

    PSource { id: opt; sujet: "options"; Component.onCompleted: recharger() }
    property var d: opt.donnees || ({})

    PCarte {
        titre: "SafeZone"
        PLigne {
            glyphe: ""; teinte: "#22c55e"
            titre: "Coffre SafeZone"
            detail: "Les versions précédentes de tes fichiers protégés (Super+S pour protéger un fichier)"
            fleche: true
            onClique: Etat.lancer(["thunar", "/.nexusvault"])
        }
        PLigne {
            glyphe: "\uf03a"; teinte: "#14b8a6"
            titre: "Liste des fichiers protégés"
            detail: "Affiche ce que SafeZone surveille"
            fleche: true
            separateur: false
            onClique: Etat.lancer(["kitty", "--hold", "nexus-safezone", "--list"])
        }
    }

    PCarte {
        titre: "Verrouillage"
        PLigne {
            glyphe: ""; teinte: "#2f6bff"
            titre: "Verrouiller maintenant"
            detail: "Raccourci : Super+Maj+L"
            fleche: true
            separateur: false
            onClique: { Etat.parametresOuverts = false; Etat.lancer(["hyprlock"]); }
        }
    }

    PCarte {
        titre: "Accès"
        PLigne {
            glyphe: ""; teinte: page.d.ssh ? "#f59e0b" : "#22c55e"
            titre: "Accès à distance (SSH)"
            detail: page.d.ssh ? "Actif — à couper si tu ne t'en sers pas" : "Désactivé"
            fleche: true
            onClique: Etat.pageParametres = "options"
        }
        PLigne {
            glyphe: ""; teinte: "#3b82f6"
            titre: "Snapshots de sécurité"
            detail: "Retour en arrière possible après une mise à jour ratée"
            fleche: true
            separateur: false
            onClique: Etat.pageParametres = "maj"
        }
    }
}
