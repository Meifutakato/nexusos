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

    Menu {}

    // Commande pour les raccourcis clavier :
    //   quickshell ipc call menu basculer
    IpcHandler {
        target: "menu"
        function basculer(): void { Etat.basculerMenu(); }
        function ouvrir(): void { Etat.menuOuvert = true; }
        function fermer(): void { Etat.menuOuvert = false; }
    }
}
