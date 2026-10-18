//! Configuration : ~/.config/nexusos/veille.toml (valeurs par défaut si absent).
//! Format : `cle = valeur`, commentaires avec `#`, liste `exceptions = ["a", "b"]` (sur une ou plusieurs lignes).

use std::path::PathBuf;

#[derive(Clone, Debug)]
pub struct Config {
    /// Temps hors écran avant qu'une appli soit mise en veille.
    pub geler_apres_secondes: u64,
    /// Fréquence de vérification.
    pub intervalle_secondes: u64,
    /// Part de la mémoire de l'appli à envoyer dans zram (0.0 à 1.0).
    pub part_a_compresser: f64,
    /// Au-dessus de ce % de CPU, l'appli travaille (téléchargement, calcul…) : on n'y touche pas.
    pub seuil_cpu_pourcent: f64,
    /// Si zram est rempli au-delà de ce %, on gèle sans compresser (sinon ça partirait sur le disque, plus lent).
    pub zram_max_pourcent: f64,
    /// Applis jamais mises en veille (début du nom de classe Hyprland, sans tenir compte des majuscules).
    pub exceptions: Vec<String>,
}

impl Default for Config {
    fn default() -> Self {
        Config {
            geler_apres_secondes: 300,
            intervalle_secondes: 15,
            part_a_compresser: 0.8,
            seuil_cpu_pourcent: 5.0,
            zram_max_pourcent: 90.0,
            exceptions: [
                "steam", "gamescope", "lutris", "heroic", // jeux
                "mpv", "vlc", "spotify", "rhythmbox", // son / vidéo
                "discord", "vesktop", "signal", "telegram", // messageries
                "obs", "kitty", // capture, terminal
            ]
            .iter()
            .map(|s| s.to_string())
            .collect(),
        }
    }
}

fn sans_commentaire(ligne: &str) -> &str {
    let mut dans_texte = false;
    for (i, c) in ligne.char_indices() {
        match c {
            '"' => dans_texte = !dans_texte,
            '#' if !dans_texte => return &ligne[..i],
            _ => {}
        }
    }
    ligne
}

fn nombre<T: std::str::FromStr>(cle: &str, val: &str) -> Result<T, String> {
    val.parse().map_err(|_| format!("« {cle} » : nombre attendu, trouvé « {val} »"))
}

fn liste(val: &str) -> Result<Vec<String>, String> {
    let interieur = val
        .strip_prefix('[')
        .and_then(|v| v.strip_suffix(']'))
        .ok_or("« exceptions » : liste entre [ ] attendue")?;
    interieur
        .split(',')
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .map(|s| {
            s.strip_prefix('"')
                .and_then(|s| s.strip_suffix('"'))
                .map(String::from)
                .ok_or_else(|| format!("« exceptions » : texte entre guillemets attendu, trouvé {s}"))
        })
        .collect()
}

impl Config {
    pub fn chemin() -> PathBuf {
        let base = std::env::var_os("XDG_CONFIG_HOME")
            .map(PathBuf::from)
            .unwrap_or_else(|| {
                PathBuf::from(std::env::var_os("HOME").unwrap_or_default()).join(".config")
            });
        base.join("nexusos").join("veille.toml")
    }

    pub fn depuis_texte(texte: &str) -> Result<Config, String> {
        let mut c = Config::default();
        let mut instruction = String::new();
        let mut debut = 0;
        for (n, brute) in texte.lines().enumerate() {
            let ligne = sans_commentaire(brute).trim();
            if instruction.is_empty() {
                if ligne.is_empty() {
                    continue;
                }
                debut = n + 1;
            }
            instruction.push_str(ligne);
            instruction.push(' ');
            // Liste sur plusieurs lignes : on attend le « ] ».
            if instruction.matches('[').count() > instruction.matches(']').count() {
                continue;
            }
            let texte_instr = std::mem::take(&mut instruction);
            let (cle, val) = texte_instr
                .split_once('=')
                .ok_or_else(|| format!("ligne {debut} : « = » manquant"))?;
            let (cle, val) = (cle.trim(), val.trim());
            match cle {
                "geler_apres_secondes" => c.geler_apres_secondes = nombre(cle, val)?,
                "intervalle_secondes" => c.intervalle_secondes = nombre(cle, val)?,
                "part_a_compresser" => c.part_a_compresser = nombre(cle, val)?,
                "seuil_cpu_pourcent" => c.seuil_cpu_pourcent = nombre(cle, val)?,
                "zram_max_pourcent" => c.zram_max_pourcent = nombre(cle, val)?,
                "exceptions" => c.exceptions = liste(val)?,
                autre => return Err(format!("ligne {debut} : réglage inconnu « {autre} »")),
            }
        }
        if !instruction.is_empty() {
            return Err(format!("ligne {debut} : « ] » manquant"));
        }
        Ok(c)
    }

    pub fn charger() -> Config {
        let chemin = Self::chemin();
        match std::fs::read_to_string(&chemin) {
            Ok(texte) => Self::depuis_texte(&texte).unwrap_or_else(|e| {
                eprintln!("⚠ {} : {e} — valeurs par défaut utilisées", chemin.display());
                Config::default()
            }),
            Err(_) => Config::default(),
        }
    }

    pub fn est_exception(&self, classe: &str) -> bool {
        let c = classe.to_lowercase();
        // Les jeux Steam ont une classe « steam_app_XXXX » : couverts par « steam ».
        self.exceptions.iter().any(|e| c.starts_with(&e.to_lowercase()))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn exceptions_par_prefixe() {
        let c = Config::default();
        assert!(c.est_exception("steam_app_1091500"));
        assert!(c.est_exception("Spotify"));
        assert!(!c.est_exception("firefox"));
    }

    #[test]
    fn fichier_complet() {
        let c = Config::depuis_texte(
            "# test\ngeler_apres_secondes = 30  # court\npart_a_compresser = 0.5\n\
             exceptions = [\n  \"mpv\",   # vidéo\n  \"jeu#1\",\n]\n",
        )
        .unwrap();
        assert_eq!(c.geler_apres_secondes, 30);
        assert_eq!(c.intervalle_secondes, 15);
        assert_eq!(c.part_a_compresser, 0.5);
        assert_eq!(c.exceptions, vec!["mpv", "jeu#1"]);
    }

    #[test]
    fn fichier_livre_valide() {
        let c = Config::depuis_texte(include_str!("../systeme/veille.toml")).unwrap();
        assert_eq!(c.exceptions, Config::default().exceptions);
        assert_eq!(c.geler_apres_secondes, 300);
    }

    #[test]
    fn erreurs_lisibles() {
        assert!(Config::depuis_texte("inconnu = 1").is_err());
        assert!(Config::depuis_texte("geler_apres_secondes = beaucoup").is_err());
        assert!(Config::depuis_texte("exceptions = [\"a\"").is_err());
    }
}
