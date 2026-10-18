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
    pub adresse: String,
    pub pid: i32,
    pub classe: String,
    pub espace: i64,
}

/// Ce qui est affiché en ce moment.
#[derive(Debug, Default)]
pub struct Ecran {
    /// Espaces de travail visibles (un par écran + espace spécial ouvert).
    pub visibles: HashSet<i64>,
    /// Fenêtre réellement active. `None` sur un espace vide : on ne se fie PAS à
    /// focusHistoryID, qui garde l'ancienne fenêtre en tête quand rien ne prend le relais.
    pub active: Option<String>,
}

impl Ecran {
    pub fn regarde(&self, f: &Fenetre) -> bool {
        self.active.as_deref() == Some(f.adresse.as_str()) || self.visibles.contains(&f.espace)
    }
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
                adresse: f.champ("address").and_then(Json::texte).unwrap_or("").to_string(),
                pid: f.champ("pid")?.entier()? as i32,
                classe: f.champ("class").and_then(Json::texte).unwrap_or("").to_string(),
                espace: id_espace(f, "workspace")?,
            })
        })
        .collect())
}

/// Ce qui est à l'écran : espaces visibles + fenêtre réellement active.
pub fn ecran(dossier: &Path) -> io::Result<Ecran> {
    let j = lire_json(&requete(dossier, "j/monitors")?)?;
    let ecrans = j.liste().ok_or_else(|| io::Error::other("liste d'écrans attendue"))?;
    let mut visibles = HashSet::new();
    for e in ecrans {
        if let Some(id) = id_espace(e, "activeWorkspace") {
            visibles.insert(id);
        }
        if let Some(id) = id_espace(e, "specialWorkspace").filter(|id| *id != 0) {
            visibles.insert(id);
        }
    }
    // « {} » quand aucune fenêtre n'a le focus (espace vide).
    let active = lire_json(&requete(dossier, "j/activewindow")?)?
        .champ("address")
        .and_then(Json::texte)
        .filter(|a| !a.is_empty())
        .map(String::from);
    Ok(Ecran { visibles, active })
}

#[cfg(test)]
mod tests {
    use super::*;

    fn fenetre(adresse: &str, espace: i64) -> Fenetre {
        Fenetre { adresse: adresse.into(), pid: 1, classe: "firefox".into(), espace }
    }

    #[test]
    fn espace_vide_ne_compte_pas_comme_regarde() {
        // Firefox sur l'espace 1, on est sur l'espace 2 vide : plus de fenêtre active.
        let e = Ecran { visibles: [2].into(), active: None };
        assert!(!e.regarde(&fenetre("0xabc", 1)));
        // Retour sur l'espace 1.
        let e = Ecran { visibles: [1].into(), active: Some("0xabc".into()) };
        assert!(e.regarde(&fenetre("0xabc", 1)));
        // Fenêtre active mais déplacée ailleurs (ex. espace spécial) : toujours regardée.
        let e = Ecran { visibles: [3].into(), active: Some("0xabc".into()) };
        assert!(e.regarde(&fenetre("0xabc", 1)));
    }
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
