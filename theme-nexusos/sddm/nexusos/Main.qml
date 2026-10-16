// NexusOS — écran de connexion (SDDM, Qt 6)
import QtQuick 2.15

Rectangle {
    id: racine
    width: 1920
    height: 1080
    color: "#060c22"

    readonly property color cTexte: "#e6ecff"
    readonly property color cDiscret: "#9aa8d6"
    readonly property color cAccent: "#2f6bff"
    readonly property color cBord: Qt.rgba(79/255, 139/255, 1, 0.75)
    readonly property string police: "Noto Sans"

    property int indexSession: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property bool enCours: false

    function connexion() {
        if (motDePasse.text === "" || enCours) return;
        enCours = true;
        message.text = "";
        sddm.login(nomUtilisateur.text, motDePasse.text, indexSession);
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            racine.enCours = false;
            motDePasse.text = "";
            message.text = "Mot de passe incorrect";
            secousse.restart();
            motDePasse.forceActiveFocus();
        }
        function onLoginSucceeded() { message.text = ""; }
    }

    // Fond galaxie
    Image {
        anchors.fill: parent
        source: "fond.jpg"
        fillMode: Image.PreserveAspectCrop
    }
    Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.25) }

    // Heure et date
    Timer { interval: 1000; running: true; repeat: true; onTriggered: horloge.maintenant = new Date() }
    Column {
        id: horloge
        property date maintenant: new Date()
        anchors { top: parent.top; topMargin: parent.height * 0.10; horizontalCenter: parent.horizontalCenter }
        spacing: 4
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(horloge.maintenant, "HH:mm")
            font.family: racine.police
            font.pixelSize: 96
            font.weight: Font.Light
            color: racine.cTexte
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            property string jour: horloge.maintenant.toLocaleDateString(Qt.locale("fr_FR"), "dddd d MMMM")
            text: jour.charAt(0).toUpperCase() + jour.slice(1)
            font.family: racine.police
            font.pixelSize: 22
            color: racine.cTexte
        }
    }

    // Carte de connexion
    Rectangle {
        id: carte
        width: 400
        height: colonne.implicitHeight + 56
        anchors.centerIn: parent
        anchors.verticalCenterOffset: parent.height * 0.08
        radius: 26
        color: Qt.rgba(6/255, 12/255, 34/255, 0.80)
        border.width: 1
        border.color: racine.cBord

        SequentialAnimation {
            id: secousse
            NumberAnimation { target: carte; property: "anchors.horizontalCenterOffset"; to: -12; duration: 50 }
            NumberAnimation { target: carte; property: "anchors.horizontalCenterOffset"; to: 12; duration: 70 }
            NumberAnimation { target: carte; property: "anchors.horizontalCenterOffset"; to: -6; duration: 60 }
            NumberAnimation { target: carte; property: "anchors.horizontalCenterOffset"; to: 0; duration: 50 }
        }

        Column {
            id: colonne
            anchors { top: parent.top; topMargin: 28; horizontalCenter: parent.horizontalCenter }
            width: parent.width - 56
            spacing: 16

            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 96; height: 96
                sourceSize: Qt.size(192, 192)
                source: "logo.svg"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "NexusOS"
                font.family: racine.police
                font.pixelSize: 24
                font.weight: Font.DemiBold
                color: racine.cTexte
            }

            // Nom d'utilisateur
            Rectangle {
                width: parent.width; height: 46; radius: 23
                color: Qt.rgba(1, 1, 1, 0.06)
                border.width: 1
                border.color: nomUtilisateur.activeFocus ? racine.cBord : Qt.rgba(154/255, 168/255, 214/255, 0.3)
                TextInput {
                    id: nomUtilisateur
                    anchors { fill: parent; leftMargin: 20; rightMargin: 20 }
                    verticalAlignment: TextInput.AlignVCenter
                    text: userModel.lastUser
                    font.family: racine.police
                    font.pixelSize: 15
                    color: racine.cTexte
                    KeyNavigation.tab: motDePasse
                    Keys.onReturnPressed: motDePasse.forceActiveFocus()
                    Text {
                        visible: nomUtilisateur.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Nom d'utilisateur"
                        font: nomUtilisateur.font
                        color: racine.cDiscret
                    }
                }
            }

            // Mot de passe
            Rectangle {
                width: parent.width; height: 46; radius: 23
                color: Qt.rgba(1, 1, 1, 0.06)
                border.width: 1
                border.color: motDePasse.activeFocus ? racine.cBord : Qt.rgba(154/255, 168/255, 214/255, 0.3)
                TextInput {
                    id: motDePasse
                    anchors { fill: parent; leftMargin: 20; rightMargin: 20 }
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    passwordCharacter: "●"
                    font.family: racine.police
                    font.pixelSize: 15
                    color: racine.cTexte
                    focus: true
                    KeyNavigation.tab: nomUtilisateur
                    Keys.onReturnPressed: racine.connexion()
                    Keys.onEnterPressed: racine.connexion()
                    Text {
                        visible: motDePasse.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Mot de passe"
                        font.family: racine.police
                        font.pixelSize: 15
                        color: racine.cDiscret
                    }
                }
            }

            // Bouton Se connecter
            Rectangle {
                width: parent.width; height: 46; radius: 23
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: zoneConnexion.containsMouse ? "#4f8bff" : "#2f6bff" }
                    GradientStop { position: 1.0; color: "#8b5cf6" }
                }
                opacity: racine.enCours ? 0.6 : 1
                Text {
                    anchors.centerIn: parent
                    text: racine.enCours ? "Connexion…" : "Se connecter"
                    font.family: racine.police
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    color: "white"
                }
                MouseArea {
                    id: zoneConnexion
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: racine.connexion()
                }
            }

            Text {
                id: message
                anchors.horizontalCenter: parent.horizontalCenter
                text: ""
                visible: text !== ""
                font.family: racine.police
                font.pixelSize: 13
                color: "#ff6b6b"
            }
        }
    }

    // Session (cliquer pour changer)
    Rectangle {
        anchors { left: parent.left; bottom: parent.bottom; margins: 28 }
        height: 40
        width: texteSession.implicitWidth + 36
        radius: 20
        color: zoneSession.containsMouse ? Qt.rgba(79/255, 139/255, 1, 0.25) : Qt.rgba(6/255, 12/255, 34/255, 0.7)
        border.width: 1
        border.color: racine.cBord
        Repeater {
            id: sessions
            model: sessionModel
            Item { property string nomSession: model.name }
        }
        Text {
            id: texteSession
            anchors.centerIn: parent
            text: "Session : " + (sessions.count > 0 && sessions.itemAt(racine.indexSession)
                  ? sessions.itemAt(racine.indexSession).nomSession : "")
            font.family: racine.police
            font.pixelSize: 13
            color: racine.cTexte
        }
        MouseArea {
            id: zoneSession
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (sessions.count > 0) racine.indexSession = (racine.indexSession + 1) % sessions.count
        }
    }

    // Redémarrer / éteindre
    Row {
        anchors { right: parent.right; bottom: parent.bottom; margins: 28 }
        spacing: 12
        Repeater {
            model: [
                { texte: "Redémarrer", action: "reboot", possible: sddm.canReboot },
                { texte: "Éteindre", action: "poweroff", possible: sddm.canPowerOff }
            ]
            Rectangle {
                required property var modelData
                visible: modelData.possible
                height: 40
                width: texteAlim.implicitWidth + 36
                radius: 20
                color: zoneAlim.containsMouse ? Qt.rgba(79/255, 139/255, 1, 0.25) : Qt.rgba(6/255, 12/255, 34/255, 0.7)
                border.width: 1
                border.color: racine.cBord
                Text {
                    id: texteAlim
                    anchors.centerIn: parent
                    text: modelData.texte
                    font.family: racine.police
                    font.pixelSize: 13
                    color: racine.cTexte
                }
                MouseArea {
                    id: zoneAlim
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.action === "reboot" ? sddm.reboot() : sddm.powerOff()
                }
            }
        }
    }

    Component.onCompleted: {
        if (nomUtilisateur.text === "") nomUtilisateur.forceActiveFocus();
        else motDePasse.forceActiveFocus();
    }
}
