// NexusOS — menu Démarrer
// Ouverture : bouton NexusOS ou « Rechercher » de la barre, ou Super+Espace.
// Fermeture : Échap, clic à côté, ou lancement d'une application.
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: menu

    // ── Réglages faciles à modifier ─────────────────────────────
    // Applications de la section « Épinglé » (12 maximum, celles non installées sont ignorées)
    property var epingles: [
        "firefox", "microsoft-edge", "onlyoffice-desktopeditors",
        "libreoffice-writer", "libreoffice-calc", "libreoffice-impress",
        "thunar", "kitty", "org.gnome.Loupe", "ristretto", "steam", "discord",
        "spotify", "com.heroicgameslauncher.hgl", "btop", "org.pulseaudio.pavucontrol"
    ]
    // Cartes « Recommandé » : catégorie freedesktop des applications à montrer
    property var recommandes: [
        { titre: "Jeux", detail: "Lanceurs et bibliothèque", categorie: "Game", glyphe: "", couleur: "#8b5cf6" },
        { titre: "Création", detail: "Dessin, photo, 3D", categorie: "Graphics", glyphe: "", couleur: "#2f6bff" },
        { titre: "Bureau & Productivité", detail: "Documents, tableurs, notes", categorie: "Office", glyphe: "", couleur: "#0ea5e9" }
    ]

    // ── Fenêtre ─────────────────────────────────────────────────
    visible: Etat.menuOuvert
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "nexus-menu"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // page affichée à droite : "accueil", "applications" ou "categorie"
    property string page: "accueil"
    property string categorie: ""
    property string titrePage: ""
    property bool alimentationOuverte: false
    property var recents: []

    onVisibleChanged: {
        if (visible) {
            champ.text = "";
            if (Etat.pageDemandee !== "") {
                page = Etat.pageDemandee;
                categorie = Etat.categorieDemandee;
                titrePage = Etat.titreDemande;
                Etat.pageDemandee = "";
            } else {
                page = "accueil";
            }
            alimentationOuverte = false;
            fichierRecents.reload();
            boite.opacity = 0;
            boite.scale = 0.96;
            apparition.restart();
            champ.forceActiveFocus();
        }
    }

    // ── Données ─────────────────────────────────────────────────
    // Toutes les applications visibles, triées par nom
    property var toutes: {
        const vals = DesktopEntries.applications.values;
        const res = [];
        for (let i = 0; i < vals.length; i++)
            if (Etat.visible(vals[i])) res.push(vals[i]);
        res.sort((a, b) => a.name.localeCompare(b.name, "fr"));
        return res;
    }

    property var listeEpingles: {
        DesktopEntries.applications.values;
        const res = [];
        for (let i = 0; i < epingles.length && res.length < 12; i++) {
            const e = DesktopEntries.byId(epingles[i]);
            if (e && res.indexOf(e) < 0) res.push(e);
        }
        return res;
    }

    function texteDe(e) {
        return (e.name + " " + e.genericName + " " + String(e.keywords) + " " + e.comment).toLowerCase();
    }

    property var resultats: {
        const q = champ.text.trim().toLowerCase();
        if (q === "") return [];
        // d'abord les noms qui commencent par la recherche, puis le reste
        const debut = [], ailleurs = [];
        for (let i = 0; i < toutes.length; i++) {
            const e = toutes[i];
            if (e.name.toLowerCase().indexOf(q) === 0) debut.push(e);
            else if (texteDe(e).indexOf(q) >= 0) ailleurs.push(e);
        }
        return debut.concat(ailleurs);
    }

    property var listeCategorie: {
        const res = [];
        for (let i = 0; i < toutes.length; i++)
            if (String(toutes[i].categories).indexOf(categorie) >= 0) res.push(toutes[i]);
        return res;
    }

    // Applications montrées dans la grande grille selon la page
    property var grille: champ.text.trim() !== "" ? resultats
                       : (page === "categorie" ? listeCategorie : toutes)

    // Fichiers récents (liste tenue par les applications GTK)
    FileView {
        id: fichierRecents
        path: Quickshell.env("HOME") + "/.local/share/recently-used.xbel"
        printErrors: false
        onLoaded: menu.recents = menu.analyserRecents(text())
        onLoadFailed: menu.recents = []
    }

    function analyserRecents(xml) {
        const re = /<bookmark\s+href="([^"]+)"[^>]*?modified="([^"]+)"/g;
        const liste = [];
        let m;
        while ((m = re.exec(xml)) !== null) {
            if (m[1].indexOf("file://") !== 0) continue;
            let chemin = m[1].substring(7);
            try { chemin = decodeURIComponent(chemin); } catch (err) {}
            liste.push({ chemin: chemin, nom: chemin.split("/").pop(), date: Date.parse(m[2]) });
        }
        liste.sort((a, b) => b.date - a.date);
        return liste.slice(0, 4);
    }

    function ilYa(date) {
        const min = Math.max(0, Math.round((Date.now() - date) / 60000));
        if (min < 1) return "À l'instant";
        if (min < 60) return "Il y a " + min + " min";
        const h = Math.round(min / 60);
        if (h < 24) return "Il y a " + h + " h";
        const j = Math.round(h / 24);
        return j === 1 ? "Hier" : "Il y a " + j + " jours";
    }

    function iconeFichier(nom) {
        const ext = nom.split(".").pop().toLowerCase();
        if (["png", "jpg", "jpeg", "gif", "webp", "svg", "bmp"].indexOf(ext) >= 0) return "image-x-generic";
        if (["mp4", "mkv", "webm", "avi", "mov"].indexOf(ext) >= 0) return "video-x-generic";
        if (["mp3", "flac", "ogg", "wav", "m4a"].indexOf(ext) >= 0) return "audio-x-generic";
        if (ext === "pdf") return "application-pdf";
        if (["odt", "doc", "docx"].indexOf(ext) >= 0) return "x-office-document";
        if (["ods", "xls", "xlsx", "csv"].indexOf(ext) >= 0) return "x-office-spreadsheet";
        if (["odp", "ppt", "pptx"].indexOf(ext) >= 0) return "x-office-presentation";
        if (["zip", "tar", "gz", "xz", "7z", "rar"].indexOf(ext) >= 0) return "package-x-generic";
        return "text-x-generic";
    }

    function ouvrirFichier(chemin) {
        Etat.lancer(["sh", "-c", 'xdg-open "$1" || thunar "$1"', "sh", chemin]);
        Etat.menuOuvert = false;
    }

    // Ouvre un dossier personnel (Documents, Images…) dans le gestionnaire de fichiers
    function ouvrirDossier(cle, nomParDefaut) {
        Etat.lancer(["sh", "-c",
            'd=$(xdg-user-dir "$1" 2>/dev/null); if [ -z "$d" ] || [ "$d" = "$HOME" ]; then d="$HOME/$2"; fi; mkdir -p "$d"; thunar "$d"',
            "sh", cle, nomParDefaut]);
        Etat.menuOuvert = false;
    }

    function afficherCategorie(cat, titre) {
        champ.text = "";
        categorie = cat;
        titrePage = titre;
        page = "categorie";
    }

    // ── Petits éléments réutilisés ──────────────────────────────
    // Tuile d'application (icône + nom)
    component TuileAppli: Item {
        id: tuile
        required property var appli
        width: 104; height: 92

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: zoneTuile.containsMouse ? Etat.cSurvol : "transparent"
            Behavior on color { ColorAnimation { duration: 110 } }
        }
        IconImage {
            id: iconeTuile
            anchors { top: parent.top; topMargin: 10; horizontalCenter: parent.horizontalCenter }
            implicitSize: 42
            source: Quickshell.iconPath(tuile.appli.icon, "application-x-executable")
            scale: zoneTuile.pressed ? 0.9 : (zoneTuile.containsMouse ? 1.08 : 1)
            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
        }
        Text {
            anchors { top: iconeTuile.bottom; topMargin: 8; left: parent.left; right: parent.right; leftMargin: 4; rightMargin: 4 }
            text: tuile.appli.name
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            font.family: Etat.police
            font.pixelSize: 12
            color: Etat.cTexte
        }
        MouseArea {
            id: zoneTuile
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Etat.ouvrir(tuile.appli)
        }
    }

    // Entrée de la colonne de gauche
    component EntreeGauche: Rectangle {
        id: entree
        property string glyphe
        property string libelle
        property bool actif: false
        signal clique()
        Layout.fillWidth: true
        Layout.preferredHeight: 38
        radius: 10
        color: actif ? Etat.cAccent2 : (zoneEntree.containsMouse ? Etat.cSurvol : "transparent")
        Behavior on color { ColorAnimation { duration: 110 } }

        Text {
            id: glypheEntree
            anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
            width: 22
            text: entree.glyphe
            horizontalAlignment: Text.AlignHCenter
            font.family: Etat.icones
            font.pixelSize: 16
            color: Etat.cTexte
        }
        Text {
            anchors { left: glypheEntree.right; leftMargin: 12; verticalCenter: parent.verticalCenter }
            text: entree.libelle
            font.family: Etat.police
            font.pixelSize: 13
            color: Etat.cTexte
        }
        MouseArea {
            id: zoneEntree
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: entree.clique()
        }
    }

    // Titre de section avec lien « Plus › » à droite
    component TitreSection: Item {
        id: titreSection
        property string titre
        property string lien: ""
        signal lienClique()
        Layout.fillWidth: true
        implicitHeight: 26
        Text {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            text: titreSection.titre
            font.family: Etat.police
            font.pixelSize: 14
            font.weight: Font.DemiBold
            color: Etat.cTexte
        }
        Text {
            visible: titreSection.lien !== ""
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            text: titreSection.lien + "  ›"
            font.family: Etat.police
            font.pixelSize: 12
            color: zoneLien.containsMouse ? Etat.cTexte : Etat.cDiscret
            MouseArea {
                id: zoneLien
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: titreSection.lienClique()
            }
        }
    }

    // ── Dessin ──────────────────────────────────────────────────
    // Fond légèrement assombri : un clic dessus ferme le menu
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.18)
        MouseArea {
            anchors.fill: parent
            onClicked: Etat.menuOuvert = false
        }
    }

    ParallelAnimation {
        id: apparition
        NumberAnimation { target: boite; property: "opacity"; to: 1; duration: 160; easing.type: Easing.OutCubic }
        NumberAnimation { target: boite; property: "scale"; to: 1; duration: 200; easing.type: Easing.OutBack }
    }

    Rectangle {
        id: boite
        width: Math.min(860, menu.width - 40)
        height: Math.min(640, menu.height - 140)
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -20
        radius: 22
        color: Etat.cFond
        border.width: 1
        border.color: Etat.cBord

        // les clics dans la boîte ne ferment pas le menu
        MouseArea { anchors.fill: parent; onClicked: menu.alimentationOuverte = false }

        // reflet verre
        Rectangle {
            anchors { fill: parent; margins: 1 }
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.06) }
                GradientStop { position: 0.35; color: Qt.rgba(1, 1, 1, 0.0) }
            }
        }

        ColumnLayout {
            anchors { fill: parent; margins: 18 }
            spacing: 16

            // ── Recherche ──
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: 22
                color: Etat.cCase
                border.width: 1
                border.color: champ.activeFocus ? Etat.cBord : Etat.cLigne

                Text {
                    id: loupe
                    anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
                    text: ""
                    font.family: Etat.icones
                    font.pixelSize: 16
                    color: Etat.cDiscret
                }
                TextInput {
                    id: champ
                    anchors { left: loupe.right; leftMargin: 12; right: parent.right; rightMargin: 18; verticalCenter: parent.verticalCenter }
                    font.family: Etat.police
                    font.pixelSize: 14
                    color: Etat.cTexte
                    selectionColor: Etat.cAccent2
                    clip: true
                    Keys.onEscapePressed: Etat.menuOuvert = false
                    Keys.onReturnPressed: {
                        if (menu.resultats.length > 0) Etat.ouvrir(menu.resultats[0]);
                    }
                    Keys.onEnterPressed: {
                        if (menu.resultats.length > 0) Etat.ouvrir(menu.resultats[0]);
                    }
                    Text {
                        visible: champ.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Rechercher des applications, des fichiers, des paramètres…"
                        font: champ.font
                        color: Etat.cDiscret
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 16

                // ── Colonne de gauche ──
                ColumnLayout {
                    Layout.preferredWidth: 190
                    Layout.maximumWidth: 190
                    Layout.fillHeight: true
                    spacing: 4

                    EntreeGauche {
                        glyphe: ""; libelle: "Accueil"
                        actif: menu.page === "accueil" && champ.text === ""
                        onClique: { champ.text = ""; menu.page = "accueil"; }
                    }
                    EntreeGauche {
                        glyphe: ""; libelle: "Applications"
                        actif: menu.page === "applications" && champ.text === ""
                        onClique: { champ.text = ""; menu.page = "applications"; }
                    }
                    EntreeGauche { glyphe: ""; libelle: "Documents";       onClique: menu.ouvrirDossier("DOCUMENTS", "Documents") }
                    EntreeGauche { glyphe: ""; libelle: "Images";          onClique: menu.ouvrirDossier("PICTURES", "Images") }
                    EntreeGauche { glyphe: ""; libelle: "Musique";         onClique: menu.ouvrirDossier("MUSIC", "Musique") }
                    EntreeGauche { glyphe: ""; libelle: "Vidéos";          onClique: menu.ouvrirDossier("VIDEOS", "Vidéos") }
                    EntreeGauche { glyphe: ""; libelle: "Téléchargements"; onClique: menu.ouvrirDossier("DOWNLOAD", "Téléchargements") }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        Layout.topMargin: 8
                        Layout.bottomMargin: 8
                        color: Etat.cLigne
                    }

                    EntreeGauche {
                        glyphe: ""; libelle: "Paramètres"
                        onClique: {
                            Etat.bientot("Les Paramètres NexusOS");
                            Etat.menuOuvert = false;
                        }
                    }
                    EntreeGauche {
                        id: boutonAlim
                        glyphe: ""; libelle: "Alimentation"
                        actif: menu.alimentationOuverte
                        onClique: menu.alimentationOuverte = !menu.alimentationOuverte
                    }

                    Item { Layout.fillHeight: true }

                    // Utilisateur
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Rectangle {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            radius: 20
                            color: Qt.rgba(1, 1, 1, 0.10)
                            clip: true
                            Text {
                                anchors.centerIn: parent
                                visible: photo.status !== Image.Ready
                                text: ""
                                font.family: Etat.icones
                                font.pixelSize: 18
                                color: Etat.cTexte
                            }
                            Image {
                                id: photo
                                anchors.fill: parent
                                source: "file://" + Quickshell.env("HOME") + "/.face"
                                fillMode: Image.PreserveAspectCrop
                                visible: status === Image.Ready
                            }
                        }
                        Column {
                            Layout.fillWidth: true
                            Text {
                                property string u: String(Quickshell.env("USER") || "")
                                text: u.charAt(0).toUpperCase() + u.slice(1)
                                font.family: Etat.police
                                font.pixelSize: 13
                                color: Etat.cTexte
                            }
                            Row {
                                spacing: 6
                                Rectangle { width: 7; height: 7; radius: 4; color: "#22c55e"; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "En ligne"; font.family: Etat.police; font.pixelSize: 11; color: Etat.cDiscret }
                            }
                        }
                    }
                }

                // Séparateur vertical
                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    color: Etat.cLigne
                }

                // ── Partie droite ──
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    // Page d'accueil
                    ColumnLayout {
                        anchors.fill: parent
                        visible: menu.page === "accueil" && champ.text.trim() === ""
                        spacing: 10

                        TitreSection {
                            titre: "Épinglé"
                            lien: "Toutes les applications"
                            onLienClique: menu.page = "applications"
                        }
                        Grid {
                            columns: 6
                            spacing: 2
                            Repeater {
                                model: menu.listeEpingles
                                TuileAppli { required property var modelData; appli: modelData }
                            }
                        }
                        Text {
                            visible: menu.listeEpingles.length === 0
                            text: "Aucune application épinglée installée."
                            font.family: Etat.police; font.pixelSize: 12; color: Etat.cDiscret
                        }

                        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Etat.cLigne }

                        TitreSection { titre: "Récents" }
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: 10
                            rowSpacing: 4
                            Repeater {
                                model: menu.recents
                                Rectangle {
                                    id: recent
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 48
                                    radius: 10
                                    color: zoneRecent.containsMouse ? Etat.cSurvol : "transparent"
                                    IconImage {
                                        id: iconeRecent
                                        anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                                        implicitSize: 32
                                        source: Quickshell.iconPath(menu.iconeFichier(recent.modelData.nom), "text-x-generic")
                                    }
                                    Column {
                                        anchors { left: iconeRecent.right; leftMargin: 10; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                                        Text {
                                            width: parent.width
                                            text: recent.modelData.nom
                                            elide: Text.ElideMiddle
                                            font.family: Etat.police; font.pixelSize: 12; color: Etat.cTexte
                                        }
                                        Text {
                                            text: menu.ilYa(recent.modelData.date)
                                            font.family: Etat.police; font.pixelSize: 11; color: Etat.cDiscret
                                        }
                                    }
                                    MouseArea {
                                        id: zoneRecent
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: menu.ouvrirFichier(recent.modelData.chemin)
                                    }
                                }
                            }
                        }
                        Text {
                            visible: menu.recents.length === 0
                            text: "Les fichiers ouverts récemment apparaîtront ici."
                            font.family: Etat.police; font.pixelSize: 12; color: Etat.cDiscret
                        }

                        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Etat.cLigne }

                        TitreSection { titre: "Recommandé" }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            Repeater {
                                model: menu.recommandes
                                Rectangle {
                                    id: carte
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 92
                                    radius: 14
                                    color: zoneCarte.containsMouse ? Etat.cSurvol : Etat.cCase
                                    border.width: 1
                                    border.color: Etat.cLigne
                                    Behavior on color { ColorAnimation { duration: 110 } }

                                    Rectangle {
                                        id: pastille
                                        anchors { left: parent.left; top: parent.top; margins: 12 }
                                        width: 36; height: 36; radius: 10
                                        color: carte.modelData.couleur
                                        Text {
                                            anchors.centerIn: parent
                                            text: carte.modelData.glyphe
                                            font.family: Etat.icones
                                            font.pixelSize: 18
                                            color: "white"
                                        }
                                    }
                                    Column {
                                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 12 }
                                        Text {
                                            width: parent.width
                                            text: carte.modelData.titre
                                            elide: Text.ElideRight
                                            font.family: Etat.police; font.pixelSize: 13; color: Etat.cTexte
                                        }
                                        Text {
                                            width: parent.width
                                            text: carte.modelData.detail
                                            elide: Text.ElideRight
                                            font.family: Etat.police; font.pixelSize: 11; color: Etat.cDiscret
                                        }
                                    }
                                    MouseArea {
                                        id: zoneCarte
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: menu.afficherCategorie(carte.modelData.categorie, carte.modelData.titre)
                                    }
                                }
                            }
                        }
                        Item { Layout.fillHeight: true }
                    }

                    // Toutes les applications / une catégorie / résultats de recherche
                    ColumnLayout {
                        anchors.fill: parent
                        visible: !(menu.page === "accueil" && champ.text.trim() === "")
                        spacing: 10

                        TitreSection {
                            titre: champ.text.trim() !== "" ? "Résultats"
                                 : (menu.page === "categorie" ? menu.titrePage : "Toutes les applications")
                            lien: "Accueil"
                            onLienClique: { champ.text = ""; menu.page = "accueil"; }
                        }
                        GridView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            cellWidth: 106
                            cellHeight: 96
                            boundsBehavior: Flickable.StopAtBounds
                            model: menu.grille
                            delegate: TuileAppli { required property var modelData; appli: modelData }
                        }
                        Text {
                            visible: menu.grille.length === 0
                            text: champ.text.trim() !== "" ? "Aucune application trouvée." : "Aucune application dans cette catégorie pour l'instant."
                            font.family: Etat.police; font.pixelSize: 12; color: Etat.cDiscret
                        }
                    }
                }
            }
        }

        // ── Menu Alimentation ──
        Rectangle {
            visible: menu.alimentationOuverte
            x: 18 + 200
            y: parent.height - height - 70
            width: 200
            height: colonneAlim.implicitHeight + 16
            radius: 14
            color: Qt.rgba(10/255, 18/255, 48/255, 0.97)
            border.width: 1
            border.color: Etat.cBord

            ColumnLayout {
                id: colonneAlim
                anchors { fill: parent; margins: 8 }
                spacing: 2
                EntreeGauche { glyphe: ""; libelle: "Verrouiller";     onClique: { Etat.menuOuvert = false; Etat.lancer(["hyprlock"]); } }
                EntreeGauche { glyphe: ""; libelle: "Se déconnecter";  onClique: Etat.lancer(["hyprctl", "dispatch", "exit"]) }
                EntreeGauche { glyphe: ""; libelle: "Redémarrer";      onClique: Etat.lancer(["systemctl", "reboot"]) }
                EntreeGauche { glyphe: ""; libelle: "Éteindre";        onClique: Etat.lancer(["systemctl", "poweroff"]) }
            }
        }
    }
}
