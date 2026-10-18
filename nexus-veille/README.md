# nexus-veille

Veille compressée des applis NexusOS, écrite en Rust, sans aucune dépendance.

Quand une appli n'est plus à l'écran depuis 5 minutes, elle est **gelée** (0 % CPU) et sa
mémoire est **compressée dans zram**. Dès qu'elle revient à l'écran (clic, changement d'espace
de travail), elle est **dégelée immédiatement** et ses données se décompressent au fil de l'eau.

## Commandes

| Commande | Rôle |
|---|---|
| `nexus-veille lance <prog>` | Lance une appli dans son propre compartiment (veille possible) |
| `nexus-veille statut` | État des applis, RAM, part compressée, zram |
| `nexus-veille degeler-tout` | Réveille tout (secours) |
| `journalctl --user -u nexus-veille -f` | Journal en direct (mises en veille / réveils) |

Réglages : `~/.config/nexusos/veille.toml` puis `systemctl --user restart nexus-veille`.

## Règles de sécurité

- Seules les applis lancées par `nexus-veille lance` (scope `app-*.scope`) sont concernées.
- Jamais : Hyprland, Xwayland, SDDM, les outils `nexus-*`, ni la liste `exceptions`.
- Une appli qui utilise du CPU (téléchargement, calcul) n'est pas gelée.
- Si zram est plein, l'appli est gelée sans compression (pas d'envoi sur le disque).
- Arrêt ou plantage du service → tout est dégelé automatiquement.

## Prérequis

Noyau ≥ 5.19 (`memory.reclaim`), cgroups v2, systemd, Hyprland, zram (phase 6).

## À améliorer plus tard

- Détecter le son (PipeWire) et le réseau au lieu d'une liste d'exceptions.
- Réglages par appli (délai différent pour le navigateur, etc.).
- Préchargement des applis fréquentes au démarrage.
