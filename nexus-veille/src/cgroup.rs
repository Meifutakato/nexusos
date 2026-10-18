//! Gel / compression via les cgroups v2 du noyau Linux.
//! - cgroup.freeze   : arrête l'appli (plus aucun CPU), réversible instantanément
//! - memory.reclaim  : pousse sa mémoire vers le swap, donc vers zram (prioritaire) — noyau ≥ 5.19

use std::fs;
use std::io;
use std::os::unix::fs::MetadataExt;
use std::path::{Path, PathBuf};

const RACINE: &str = "/sys/fs/cgroup";

/// cgroup d'un processus.
pub fn de_pid(pid: i32) -> Option<PathBuf> {
    let texte = fs::read_to_string(format!("/proc/{pid}/cgroup")).ok()?;
    let rel = texte.lines().find_map(|l| l.strip_prefix("0::"))?;
    Some(Path::new(RACINE).join(rel.trim_start_matches('/')))
}

/// Dossier des applis de l'utilisateur courant (systemd --user).
pub fn dossier_apps() -> PathBuf {
    let uid = fs::metadata("/proc/self").map(|m| m.uid()).unwrap_or(1000);
    PathBuf::from(format!(
        "{RACINE}/user.slice/user-{uid}.slice/user@{uid}.service/app.slice"
    ))
}

fn nom(chemin: &Path) -> String {
    chemin
        .file_name()
        .map(|n| n.to_string_lossy().into_owned())
        .unwrap_or_default()
}

/// Nom lisible d'un scope : app-nexus-firefox-1234.scope → nexus-firefox-1234
pub fn nom_court(chemin: &Path) -> String {
    let n = nom(chemin);
    n.trim_start_matches("app-").trim_end_matches(".scope").to_string()
}

fn est_scope_app(chemin: &Path) -> bool {
    let n = nom(chemin);
    n.starts_with("app-") && n.ends_with(".scope")
}

/// Sécurité : on ne touche qu'à un compartiment propre à une appli,
/// jamais à celui du bureau (Hyprland, Xwayland) ni des outils NexusOS.
pub fn est_dediee(chemin: &Path) -> bool {
    est_scope_app(chemin)
        && chemin.to_string_lossy().contains("/app.slice/")
        && !contient_processus_protege(chemin)
}

fn contient_processus_protege(chemin: &Path) -> bool {
    let procs = fs::read_to_string(chemin.join("cgroup.procs")).unwrap_or_default();
    procs.lines().any(|pid| {
        fs::read_to_string(format!("/proc/{}/comm", pid.trim()))
            .map(|c| {
                let c = c.trim();
                c == "Hyprland" || c == "Xwayland" || c == "sddm" || c.starts_with("nexus-")
            })
            .unwrap_or(false)
    })
}

pub fn lire_u64(chemin: &Path, fichier: &str) -> Option<u64> {
    fs::read_to_string(chemin.join(fichier)).ok()?.trim().parse().ok()
}

pub fn est_gelee(chemin: &Path) -> bool {
    fs::read_to_string(chemin.join("cgroup.freeze"))
        .map(|s| s.trim() == "1")
        .unwrap_or(false)
}

pub fn geler(chemin: &Path) -> io::Result<()> {
    fs::write(chemin.join("cgroup.freeze"), "1")
}

pub fn degeler(chemin: &Path) -> io::Result<()> {
    fs::write(chemin.join("cgroup.freeze"), "0")
}

/// Demande au noyau de libérer `octets` de mémoire de l'appli (→ zram).
/// Une erreur EAGAIN veut seulement dire qu'il n'a pas pu tout libérer : c'est normal.
pub fn compresser(chemin: &Path, octets: u64) -> io::Result<()> {
    fs::write(chemin.join("memory.reclaim"), octets.to_string())
}

/// Temps CPU total consommé (microsecondes).
pub fn cpu_usec(chemin: &Path) -> Option<u64> {
    fs::read_to_string(chemin.join("cpu.stat"))
        .ok()?
        .lines()
        .find_map(|l| l.strip_prefix("usage_usec "))?
        .trim()
        .parse()
        .ok()
}

/// (données d'origine, RAM réellement occupée, taille max) de zram0, en octets.
pub fn zram_stats() -> Option<(u64, u64, u64)> {
    let mm = fs::read_to_string("/sys/block/zram0/mm_stat").ok()?;
    let champs: Vec<u64> = mm.split_whitespace().filter_map(|x| x.parse().ok()).collect();
    let taille: u64 = fs::read_to_string("/sys/block/zram0/disksize")
        .ok()?
        .trim()
        .parse()
        .ok()?;
    Some((*champs.first()?, *champs.get(2)?, taille))
}

pub fn zram_pourcent() -> Option<f64> {
    let (origine, _, taille) = zram_stats()?;
    (taille > 0).then(|| origine as f64 / taille as f64 * 100.0)
}

/// Tous les compartiments d'applis de l'utilisateur.
pub fn scopes_apps() -> Vec<PathBuf> {
    let mut v: Vec<PathBuf> = fs::read_dir(dossier_apps())
        .map(|it| {
            it.filter_map(|e| e.ok().map(|e| e.path()))
                .filter(|p| est_scope_app(p))
                .collect()
        })
        .unwrap_or_default();
    v.sort();
    v
}

/// Filet de sécurité : dégèle tout (arrêt ou plantage du service).
pub fn degeler_tout() -> usize {
    scopes_apps()
        .iter()
        .filter(|s| est_gelee(s))
        .filter(|s| degeler(s).is_ok())
        .count()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn noms() {
        let p = Path::new("/sys/fs/cgroup/user.slice/user-1000.slice/user@1000.service/app.slice/app-nexus-firefox-42.scope");
        assert!(est_scope_app(p));
        assert_eq!(nom_court(p), "nexus-firefox-42");
        assert!(!est_scope_app(Path::new("/sys/fs/cgroup/user.slice/session-2.scope")));
    }
}
