// Module IA NexusOS — lit l'état de l'espace IA (nexus-ia etat) et garde le résultat
import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: source
    visible: false
    property var donnees: null
    property bool chargement: lecteur.running
    function recharger() { if (!lecteur.running) lecteur.running = true; }

    Process {
        id: lecteur
        command: ["nexus-ia", "etat"]
        stdout: SplitParser {
            onRead: ligne => {
                try { source.donnees = JSON.parse(ligne); } catch (e) {}
            }
        }
    }
}
