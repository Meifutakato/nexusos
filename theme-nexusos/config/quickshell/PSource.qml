// Paramètres NexusOS — lit un sujet (son, réseau…) avec nexus-param.py et garde le résultat
import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: source
    visible: false
    property string sujet: ""
    property var donnees: null
    property bool chargement: lecteur.running
    function recharger() { if (!lecteur.running) lecteur.running = true; }

    Process {
        id: lecteur
        command: ["python3", Etat.programmeParam, source.sujet]
        stdout: SplitParser {
            onRead: ligne => {
                try { source.donnees = JSON.parse(ligne); } catch (e) {}
            }
        }
    }
}
