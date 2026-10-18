
    // Lance une appli via nexus-veille (mise en veille possible quand elle est hors écran)
    function executer(appli) {
        if (!appli) return;
        var cmd = appli.command ? Array.from(appli.command) : [];
        if (cmd.length === 0 || appli.runInTerminal) { appli.execute(); return; }
        Quickshell.execDetached(["nexus-veille", "lance"].concat(cmd));
    }
