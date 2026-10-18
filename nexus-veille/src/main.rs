//! nexus-veille — NexusOS
//!
//! Met en veille les applis qu'on ne regarde plus : après quelques minutes hors de l'écran,
//! l'appli est gelée (0 % CPU) et sa mémoire compressée dans zram. Dès qu'on revient dessus
//! (clic, changement d'espace de travail), elle est dégelée immédiatement et ses données se
//! décompressent à la volée.
//!
//! Commandes :
//!   nexus-veille [demon]        service (lancé par systemd --user)
//!   nexus-veille lance <prog>   lance une appli dans son propre compartiment (nécessaire pour la veille)
//!   nexus-veille statut         état des applis, RAM, part compressée
//!   nexus-veille degeler-tout   réveille tout (secours)

mod cgroup;
mod config;
mod hypr;
mod json;

use config::Config;
use std::collections::HashMap;
use std::io;
use std::os::unix::process::CommandExt;
use std::path::{Path, PathBuf};
use std::process::{exit, Command};
use std::sync::mpsc::{self, RecvTimeoutError};
use std::thread;
use std::time::{Duration, Instant};

fn main() {
    let args: Vec<String> = std::env::args().skip(1).collect();
    match args.first().map(String::as_str) {
        None | Some("demon") => demon(),
        Some("lance") => lance(&args[1..]),
        Some("statut") | Some("--statut") => statut(),
        Some("degeler-tout") | Some("--degeler-tout") => {
            println!("{} appli(s) réveillée(s)", cgroup::degeler_tout());
        }
        Some("aide") | Some("--help") | Some("-h") => aide(),
        Some(autre) => {
            eprintln!("Commande inconnue : {autre}\n");
            aide();
            exit(2);
        }
    }
}

fn aide() {
    println!(
        "nexus-veille — veille compressée des applis NexusOS\n\n\
         nexus-veille lance <programme> [args]   lancer une appli (veille possible)\n\
         nexus-veille statut                     état des applis\n\
         nexus-veille degeler-tout               tout réveiller\n\
         nexus-veille demon                      service (systemd)\n\n\
         Réglages : {}",
        Config::chemin().display()
    );
}

// ---------------------------------------------------------------- lanceur

/// Nom d'unité systemd valide à partir du programme : « /usr/bin/Firefox » → « firefox »
fn nom_unite(programme: &str) -> String {
    let base = Path::new(programme)
        .file_name()
        .map(|n| n.to_string_lossy().into_owned())
        .unwrap_or_else(|| programme.to_string());
    base.chars()
        .map(|c| if c.is_ascii_alphanumeric() { c.to_ascii_lowercase() } else { '-' })
        .collect()
}

fn lance(commande: &[String]) -> ! {
    if commande.is_empty() {
        eprintln!("Usage : nexus-veille lance <programme> [args]");
        exit(2);
    }
    let unite = format!("app-nexus-{}-{}", nom_unite(&commande[0]), std::process::id());
    let erreur = Command::new("systemd-run")
        .args(["--user", "--scope", "--quiet", "--collect", "--slice=app.slice"])
        .arg(format!("--unit={unite}"))
        .arg("--")
        .args(commande)
        .exec();
    // systemd-run indisponible : on lance quand même l'appli (simplement sans veille possible).
    eprintln!("⚠ systemd-run impossible ({erreur}) — lancement direct");
    let erreur = Command::new(&commande[0]).args(&commande[1..]).exec();
    eprintln!("Impossible de lancer {} : {erreur}", commande[0]);
    exit(1);
}

// ---------------------------------------------------------------- statut

fn mo(octets: u64) -> String {
    format!("{:.0} Mo", octets as f64 / 1_048_576.0)
}

/// Pourquoi une appli est (ou n'est pas encore) en veille.
fn raison(
    cfg: &Config,
    scope: &Path,
    hypr: &Option<(Vec<hypr::Fenetre>, hypr::Ecran)>,
    cpu_pourcent: Option<f64>,
) -> String {
    if cgroup::est_gelee(scope) {
        return "en veille".into();
    }
    if !cgroup::est_dediee(scope) {
        return "protégée (bureau)".into();
    }
    let Some((fenetres, ecran)) = hypr else {
        return "Hyprland injoignable".into();
    };
    let siennes: Vec<&hypr::Fenetre> = fenetres
        .iter()
        .filter(|f| cgroup::de_pid(f.pid).as_deref() == Some(scope))
        .collect();
    if siennes.is_empty() {
        return "aucune fenêtre".into();
    }
    if let Some(f) = siennes.iter().find(|f| cfg.est_exception(&f.classe)) {
        return format!("exception ({})", f.classe);
    }
    if siennes.iter().any(|f| ecran.regarde(f)) {
        return "à l'écran".into();
    }
    match cpu_pourcent {
        Some(c) if c > cfg.seuil_cpu_pourcent => format!("travaille ({c:.0} % CPU)"),
        _ => format!("veille après {} s hors écran", cfg.geler_apres_secondes),
    }
}

fn statut() {
    let cfg = Config::charger();
    let scopes = cgroup::scopes_apps();
    if scopes.is_empty() {
        println!("Aucune appli lancée via « nexus-veille lance » pour le moment.");
    } else {
        let hypr = hypr::dossier().and_then(|d| Some((hypr::fenetres(&d).ok()?, hypr::ecran(&d).ok()?)));
        // Mesure du CPU sur 1 seconde.
        let avant: Vec<Option<u64>> = scopes.iter().map(|s| cgroup::cpu_usec(s)).collect();
        thread::sleep(Duration::from_secs(1));
        println!("{:<26} {:<7} {:>8} {:>11}  POURQUOI", "APPLI", "ÉTAT", "RAM", "COMPRESSÉE");
        for (s, a) in scopes.iter().zip(avant) {
            let cpu = match (a, cgroup::cpu_usec(s)) {
                (Some(a), Some(b)) => Some(b.saturating_sub(a) as f64 / 10_000.0),
                _ => None,
            };
            let etat = if cgroup::est_gelee(s) { "veille" } else { "active" };
            let ram = cgroup::lire_u64(s, "memory.current").unwrap_or(0);
            let swap = cgroup::lire_u64(s, "memory.swap.current").unwrap_or(0);
            println!(
                "{:<26} {:<7} {:>8} {:>11}  {}",
                cgroup::nom_court(s),
                etat,
                mo(ram),
                mo(swap),
                raison(&cfg, s, &hypr, cpu)
            );
        }
    }
    if let Some((origine, occupe, taille)) = cgroup::zram_stats() {
        let ratio = if origine >= 1_048_576 && occupe > 0 {
            format!(" (×{:.1})", origine as f64 / occupe as f64)
        } else {
            String::new()
        };
        println!(
            "\nzram : {} de données rangées dans {} de RAM{ratio} — capacité {}",
            mo(origine),
            mo(occupe),
            mo(taille)
        );
    }
}

// ---------------------------------------------------------------- démon

struct Suivi {
    derniere_activite: Instant,
    cpu_precedent: Option<(u64, Instant)>,
}

struct Groupe {
    regardee: bool,
    exception: bool,
    classe: String,
}

fn demon() {
    let cfg = Config::charger();
    println!(
        "nexus-veille démarré — veille après {} s hors écran, vérification toutes les {} s, {} exception(s)",
        cfg.geler_apres_secondes,
        cfg.intervalle_secondes,
        cfg.exceptions.len()
    );
    let reveillees = cgroup::degeler_tout();
    if reveillees > 0 {
        println!("{reveillees} appli(s) restée(s) gelée(s) réveillée(s) au démarrage");
    }

    let (tx, rx) = mpsc::channel();
    thread::spawn(move || hypr::ecouter_evenements(tx));

    let intervalle = Duration::from_secs(cfg.intervalle_secondes.max(2));
    let mut suivi: HashMap<PathBuf, Suivi> = HashMap::new();
    let mut prochaine_passe = Instant::now();
    let mut derniere_erreur: Option<String> = None;

    loop {
        let attente = prochaine_passe.saturating_duration_since(Instant::now());
        // Un événement Hyprland → passe « réveil » immédiate ; sinon passe complète périodique.
        let complete = match rx.recv_timeout(attente) {
            Ok(()) => {
                while rx.try_recv().is_ok() {} // regrouper les rafales d'événements
                false
            }
            Err(RecvTimeoutError::Timeout) => true,
            Err(RecvTimeoutError::Disconnected) => {
                thread::sleep(intervalle);
                true
            }
        };
        if complete {
            prochaine_passe = Instant::now() + intervalle;
        }
        match passe(&cfg, &mut suivi, complete) {
            Ok(()) => derniere_erreur = None,
            Err(e) => {
                let msg = e.to_string();
                if derniere_erreur.as_deref() != Some(&msg) {
                    eprintln!("[attente] Hyprland injoignable : {msg} (nouvel essai en continu)");
                    derniere_erreur = Some(msg);
                }
            }
        }
    }
}

fn passe(cfg: &Config, suivi: &mut HashMap<PathBuf, Suivi>, complete: bool) -> io::Result<()> {
    let dossier = hypr::dossier().ok_or_else(|| io::Error::other("socket introuvable"))?;
    let fenetres = hypr::fenetres(&dossier)?;
    let ecran = hypr::ecran(&dossier)?;
    let maintenant = Instant::now();

    // Une appli peut avoir plusieurs fenêtres : on raisonne par compartiment.
    let mut groupes: HashMap<PathBuf, Groupe> = HashMap::new();
    for f in &fenetres {
        if f.pid <= 0 {
            continue;
        }
        let Some(cg) = cgroup::de_pid(f.pid) else { continue };
        let regardee = ecran.regarde(f);
        let g = groupes.entry(cg).or_insert_with(|| Groupe {
            regardee: false,
            exception: false,
            classe: f.classe.clone(),
        });
        g.regardee |= regardee;
        g.exception |= cfg.est_exception(&f.classe);
    }

    for (cg, g) in &groupes {
        let s = suivi.entry(cg.clone()).or_insert(Suivi {
            derniere_activite: maintenant,
            cpu_precedent: None,
        });
        let gelee = cgroup::est_gelee(cg);

        // Appli à l'écran (ou protégée) : réveil immédiat si besoin.
        if g.regardee || g.exception {
            s.derniere_activite = maintenant;
            s.cpu_precedent = None;
            if gelee {
                match cgroup::degeler(cg) {
                    Ok(()) => println!("[réveil] {}", g.classe),
                    Err(e) => eprintln!("[erreur] réveil impossible ({}) : {e}", g.classe),
                }
            }
            continue;
        }
        if !complete || gelee {
            continue;
        }

        // Hors écran : travaille-t-elle encore (téléchargement, calcul, compilation…) ?
        let cpu = cgroup::cpu_usec(cg);
        let occupee = match (cpu, s.cpu_precedent) {
            (Some(u), Some((u0, t0))) => {
                let dt = maintenant.duration_since(t0).as_micros() as f64;
                dt > 0.0 && u.saturating_sub(u0) as f64 / dt * 100.0 > cfg.seuil_cpu_pourcent
            }
            _ => true, // pas encore deux mesures : prudence
        };
        s.cpu_precedent = cpu.map(|u| (u, maintenant));
        if occupee {
            s.derniere_activite = maintenant;
            continue;
        }

        if maintenant.duration_since(s.derniere_activite) >= Duration::from_secs(cfg.geler_apres_secondes)
            && cgroup::est_dediee(cg)
        {
            mettre_en_veille(cfg, cg, &g.classe);
        }
    }

    suivi.retain(|cg, _| groupes.contains_key(cg));
    Ok(())
}

fn mettre_en_veille(cfg: &Config, cg: &Path, classe: &str) {
    if let Err(e) = cgroup::geler(cg) {
        eprintln!("[erreur] veille impossible ({classe}) : {e}");
        return;
    }
    let ram = cgroup::lire_u64(cg, "memory.current").unwrap_or(0);
    let zram_dispo = cgroup::zram_pourcent()
        .map(|p| p < cfg.zram_max_pourcent)
        .unwrap_or(false);
    if zram_dispo && ram > 0 {
        let cible = (ram as f64 * cfg.part_a_compresser.clamp(0.0, 1.0)) as u64;
        let _ = cgroup::compresser(cg, cible); // EAGAIN = compression partielle, normal
        let apres = cgroup::lire_u64(cg, "memory.current").unwrap_or(ram);
        println!("[veille] {classe} — RAM {} → {}", mo(ram), mo(apres));
    } else {
        println!("[veille] {classe} — gelée sans compression (zram plein ou absent)");
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn noms_unites() {
        assert_eq!(nom_unite("/usr/bin/Firefox"), "firefox");
        assert_eq!(nom_unite("libreoffice --writer"), "libreoffice---writer");
        assert_eq!(nom_unite("org.gnome.Nautilus"), "org-gnome-nautilus");
    }
}
