//! Dialogue avec Hyprland par ses sockets Unix (aucune dépendance à hyprctl).

use crate::json::{self, Json};
use std::collections::HashSet;
use std::io::{self, BufRead, BufReader, Read, Write};
use std::os::unix::net::UnixStream;
use std::path::{Path, PathBuf};
use std::sync::mpsc::Sender;
use std::thread;
use std::time::Duration;

#[derive(Debug, Clone)]
pub struct Fenetre {
    pub pid: i32,
    pub classe: String,
    pub espace: i64,
    /// 0 = fenêtre actuellement au premier plan.
    pub rang_focus: i64,
}

fn id_espace(j: &Json, champ: &str) -> Option<i64> {
    j.champ(champ)?.champ("id")?.entier()
}

fn lire_json(texte: &str) -> io::Result<Json> {
    json::lire(texte).map_err(io::Error::other)
}

/// Dossier des sockets de l'instance Hyprland en cours.
pub fn dossier() -> Option<PathBuf> {
    let runtime = std::env::var_os("XDG_RUNTIME_DIR").map(PathBuf::from);
    if let Ok(sig) = std::env::var("HYPRLAND_INSTANCE_SIGNATURE") {
        let mut candidats = Vec::new();
        if let Some(r) = &runtime {
            candidats.push(r.join("hypr").join(&sig));
        }
        candidats.push(PathBuf::from("/tmp/hypr").join(&sig));
        if let Some(c) = candidats.into_iter().find(|c| c.join(".socket.sock").exists()) {
            return Some(c);
        }
    }
    // Pas de signature (ou périmée après un redémarrage de Hyprland) : instance la plus récente.
    let mut dossiers: Vec<PathBuf> = std::fs::read_dir(runtime?.join("hypr"))
        .ok()?
        .filter_map(|e| e.ok().map(|e| e.path()))
        .filter(|p| p.join(".socket.sock").exists())
        .collect();
    dossiers.sort_by_key(|p| std::fs::metadata(p).and_then(|m| m.modified()).ok());
    dossiers.pop()
}

fn requete(dossier: &Path, commande: &str) -> io::Result<String> {
    let mut s = UnixStream::connect(dossier.join(".socket.sock"))?;
    s.set_read_timeout(Some(Duration::from_secs(2)))?;
    s.write_all(commande.as_bytes())?;
    let mut sortie = String::new();
    s.read_to_string(&mut sortie)?;
    Ok(sortie)
}

pub fn fenetres(dossier: &Path) -> io::Result<Vec<Fenetre>> {
    let j = lire_json(&requete(dossier, "j/clients")?)?;
    let liste = j.liste().ok_or_else(|| io::Error::other("liste de fenêtres attendue"))?;
    Ok(liste
        .iter()
        .filter_map(|f| {
            Some(Fenetre {
                pid: f.champ("pid")?.entier()? as i32,
                classe: f.champ("class").and_then(Json::texte).unwrap_or("").to_string(),
                espace: id_espace(f, "workspace")?,
                rang_focus: f.champ("focusHistoryID").and_then(Json::entier).unwrap_or(-1),
            })
        })
        .collect())
}

/// Espaces de travail affichés en ce moment (un par écran, + l'espace spécial s'il est ouvert).
pub fn espaces_visibles(dossier: &Path) -> io::Result<HashSet<i64>> {
    let j = lire_json(&requete(dossier, "j/monitors")?)?;
    let ecrans = j.liste().ok_or_else(|| io::Error::other("liste d'écrans attendue"))?;
    let mut ids = HashSet::new();
    for e in ecrans {
        if let Some(id) = id_espace(e, "activeWorkspace") {
            ids.insert(id);
        }
        if let Some(id) = id_espace(e, "specialWorkspace").filter(|id| *id != 0) {
            ids.insert(id);
        }
    }
    Ok(ids)
}

/// Événements qui peuvent rendre une appli de nouveau visible → réveil immédiat.
const EVENEMENTS_REVEIL: &[&str] = &[
    "activewindowv2>>",
    "workspacev2>>",
    "focusedmon>>",
    "movewindowv2>>",
    "activespecial>>",
    "openwindow>>",
];

/// Écoute le flux d'événements Hyprland en continu (reconnexion automatique).
pub fn ecouter_evenements(tx: Sender<()>) {
    loop {
        if let Some(d) = dossier() {
            if let Ok(flux) = UnixStream::connect(d.join(".socket2.sock")) {
                for ligne in BufReader::new(flux).lines() {
                    let Ok(ligne) = ligne else { break };
                    if EVENEMENTS_REVEIL.iter().any(|e| ligne.starts_with(e)) && tx.send(()).is_err() {
                        return;
                    }
                }
            }
        }
        thread::sleep(Duration::from_secs(2));
    }
}
