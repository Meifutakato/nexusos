//@ pragma IconTheme Papirus-Dark
// NexusOS — interface du bureau (Quickshell)
// Étape 1 : barre du bas.  Étape 2 : menu Démarrer.
import Quickshell
import Quickshell.Io
import QtQuick

ShellRoot {
    // Une barre par écran
    Variants {
        model: Quickshell.screens
        Barre {}
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
