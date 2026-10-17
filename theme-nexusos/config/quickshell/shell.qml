//@ pragma IconTheme Papirus-Dark
// NexusOS — interface du bureau (Quickshell)
// Barre du haut (îlot), barre du bas, menu Démarrer.
import Quickshell
import Quickshell.Io
import QtQuick

ShellRoot {
    // Une barre par écran
    Variants {
        model: Quickshell.screens
        Barre {}
    }
    Variants {
        model: Quickshell.screens
        Haut {}
    }
    Variants {
        model: Quickshell.screens
        Bureau {}
    }

    Menu {}

    // Paramètres NexusOS (fenêtre)
    Parametres {}

    // Assistant IA : seulement si le module IA (ia-nexusos) est installé
    LazyLoader {
        active: Etat.iaInstalle
        source: Qt.resolvedUrl("ia/Assistant.qml")
    }

    // Trois points sur la fenêtre active (façon HyperOS)
    Poignee {}

    // Commande pour les raccourcis clavier :
    //   quickshell ipc call menu basculer
    IpcHandler {
        target: "menu"
        function basculer(): void { Etat.basculerMenu(); }
        function ouvrir(): void { Etat.menuOuvert = true; }
        function fermer(): void { Etat.menuOuvert = false; }
    }

    //   quickshell ipc call parametres ouvrir
    //   quickshell ipc call parametres page son
    IpcHandler {
        target: "parametres"
        function ouvrir(): void { Etat.ouvrirParametres("accueil"); }
        function page(nom: string): void { Etat.ouvrirParametres(nom); }
        function fermer(): void { Etat.parametresOuverts = false; }
    }

    //   quickshell ipc call assistant basculer
    //   quickshell ipc call assistant mode cv
    IpcHandler {
        target: "assistant"
        function basculer(): void {
            if (Etat.assistantOuvert) Etat.assistantOuvert = false; else Etat.ouvrirAssistant("");
        }
        function ouvrir(): void { Etat.ouvrirAssistant(""); }
        function mode(nom: string): void { Etat.ouvrirAssistant(nom); }
        function fermer(): void { Etat.assistantOuvert = false; }
    }
}
