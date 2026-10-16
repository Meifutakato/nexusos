//@ pragma IconTheme Papirus-Dark
// NexusOS — interface du bureau (Quickshell)
// Étape 1 : la barre du bas. Le menu Démarrer et l'îlot du haut viendront ensuite.
import Quickshell
import QtQuick

ShellRoot {
    // Une barre par écran
    Variants {
        model: Quickshell.screens
        Barre {}
    }
}
