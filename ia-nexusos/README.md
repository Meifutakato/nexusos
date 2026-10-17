# Module IA NexusOS (séparé du thème)

Ajoute à NexusOS un espace IA. Le thème (`theme-nexusos`) fonctionne sans lui :
tant que ce module n'est pas installé, aucune IA n'apparaît.

## Installer / retirer
```
bash /root/nexusos/ia-nexusos/install_ia_nexusos.sh                  # installer
bash /root/nexusos/ia-nexusos/install_ia_nexusos.sh --desinstaller   # retirer (garde ~/IA)
```
Le thème doit être installé avant.

## Ce que ça ajoute
- **Paramètres › Intelligence artificielle** : Assistant IA, IA locales (Ollama), IA en ligne (clé API), Agents IA.
- **Super+A** : fenêtre Assistant (discussion, CV en document LibreOffice, maquettes HTML).
- `nexus-ia` : le moteur (`nexus-ia etat`, `nexus-ia demander discussion "texte"`…).

## Rangement, rien n'est mélangé
```
~/IA/Locales/<nom>/     une IA locale
~/IA/En-ligne/<nom>/    une IA en ligne (sans la clé)
~/IA/Agents/<nom>/      un agent ; ses résultats dans travail/
~/IA/Créations/         CV et maquettes de l'assistant
~/IA/Assistant/         la conversation en cours
~/.config/nexusos/ia-cles.json   les clés API (lisibles par toi seul)
```

## Fichiers du module
```
ia-nexusos/
  install_ia_nexusos.sh   installe / retire
  nexus-ia                → /usr/local/bin
  quickshell/ia/          → ~/.config/quickshell/ia/  (pages et fenêtre)
  hypr/ia.conf            → ~/.config/hypr/ia.conf    (Super+A, règle de fenêtre)
  assistant.svg           icône
```
Dans VirtualBox les IA locales sont lentes : vrais essais en dual boot.
