//! Lecteur JSON minimal (juste ce qu'il faut pour les réponses de Hyprland).

#[derive(Debug, Clone, PartialEq)]
pub enum Json {
    Null,
    Bool(bool),
    Nombre(f64),
    Texte(String),
    Liste(Vec<Json>),
    Objet(Vec<(String, Json)>),
}

impl Json {
    pub fn champ(&self, cle: &str) -> Option<&Json> {
        match self {
            Json::Objet(v) => v.iter().find(|(k, _)| k == cle).map(|(_, j)| j),
            _ => None,
        }
    }
    pub fn entier(&self) -> Option<i64> {
        match self {
            Json::Nombre(n) => Some(*n as i64),
            _ => None,
        }
    }
    pub fn texte(&self) -> Option<&str> {
        match self {
            Json::Texte(s) => Some(s),
            _ => None,
        }
    }
    pub fn liste(&self) -> Option<&[Json]> {
        match self {
            Json::Liste(v) => Some(v),
            _ => None,
        }
    }
}

pub fn lire(source: &str) -> Result<Json, String> {
    let mut p = Lecteur { o: source.as_bytes(), i: 0 };
    let v = p.valeur()?;
    p.blancs();
    if p.i != p.o.len() {
        return Err(format!("caractères en trop à la position {}", p.i));
    }
    Ok(v)
}

struct Lecteur<'a> {
    o: &'a [u8],
    i: usize,
}

impl Lecteur<'_> {
    fn blancs(&mut self) {
        while self.i < self.o.len() && self.o[self.i].is_ascii_whitespace() {
            self.i += 1;
        }
    }

    fn courant(&self) -> Option<u8> {
        self.o.get(self.i).copied()
    }

    fn attendre(&mut self, c: u8) -> Result<(), String> {
        if self.courant() == Some(c) {
            self.i += 1;
            Ok(())
        } else {
            Err(format!("« {} » attendu à la position {}", c as char, self.i))
        }
    }

    fn mot(&mut self, mot: &str, v: Json) -> Result<Json, String> {
        if self.o[self.i..].starts_with(mot.as_bytes()) {
            self.i += mot.len();
            Ok(v)
        } else {
            Err(format!("valeur invalide à la position {}", self.i))
        }
    }

    fn valeur(&mut self) -> Result<Json, String> {
        self.blancs();
        match self.courant() {
            Some(b'{') => self.objet(),
            Some(b'[') => self.tableau(),
            Some(b'"') => Ok(Json::Texte(self.chaine()?)),
            Some(b't') => self.mot("true", Json::Bool(true)),
            Some(b'f') => self.mot("false", Json::Bool(false)),
            Some(b'n') => self.mot("null", Json::Null),
            Some(c) if c == b'-' || c.is_ascii_digit() => self.nombre(),
            _ => Err(format!("valeur attendue à la position {}", self.i)),
        }
    }

    fn objet(&mut self) -> Result<Json, String> {
        self.attendre(b'{')?;
        let mut champs = Vec::new();
        self.blancs();
        if self.courant() == Some(b'}') {
            self.i += 1;
            return Ok(Json::Objet(champs));
        }
        loop {
            self.blancs();
            let cle = self.chaine()?;
            self.blancs();
            self.attendre(b':')?;
            champs.push((cle, self.valeur()?));
            self.blancs();
            match self.courant() {
                Some(b',') => self.i += 1,
                Some(b'}') => {
                    self.i += 1;
                    return Ok(Json::Objet(champs));
                }
                _ => return Err(format!("« , » ou « }} » attendu à la position {}", self.i)),
            }
        }
    }

    fn tableau(&mut self) -> Result<Json, String> {
        self.attendre(b'[')?;
        let mut v = Vec::new();
        self.blancs();
        if self.courant() == Some(b']') {
            self.i += 1;
            return Ok(Json::Liste(v));
        }
        loop {
            v.push(self.valeur()?);
            self.blancs();
            match self.courant() {
                Some(b',') => self.i += 1,
                Some(b']') => {
                    self.i += 1;
                    return Ok(Json::Liste(v));
                }
                _ => return Err(format!("« , » ou « ] » attendu à la position {}", self.i)),
            }
        }
    }

    fn hex4(&mut self) -> Result<u32, String> {
        let bloc = self
            .o
            .get(self.i..self.i + 4)
            .and_then(|b| std::str::from_utf8(b).ok())
            .and_then(|s| u32::from_str_radix(s, 16).ok())
            .ok_or_else(|| format!("\\u invalide à la position {}", self.i))?;
        self.i += 4;
        Ok(bloc)
    }

    fn chaine(&mut self) -> Result<String, String> {
        self.attendre(b'"')?;
        let mut octets = Vec::new();
        loop {
            let c = self.courant().ok_or("texte non terminé")?;
            self.i += 1;
            match c {
                b'"' => break,
                b'\\' => {
                    let e = self.courant().ok_or("échappement non terminé")?;
                    self.i += 1;
                    let car = match e {
                        b'"' => '"',
                        b'\\' => '\\',
                        b'/' => '/',
                        b'b' => '\u{8}',
                        b'f' => '\u{c}',
                        b'n' => '\n',
                        b'r' => '\r',
                        b't' => '\t',
                        b'u' => {
                            let mut code = self.hex4()?;
                            // Paire de substitution UTF-16 (émojis, etc.)
                            if (0xD800..0xDC00).contains(&code) && self.o[self.i..].starts_with(b"\\u") {
                                self.i += 2;
                                let bas = self.hex4()?;
                                code = 0x10000 + ((code - 0xD800) << 10) + (bas.wrapping_sub(0xDC00) & 0x3FF);
                            }
                            char::from_u32(code).unwrap_or('\u{FFFD}')
                        }
                        _ => return Err(format!("échappement inconnu à la position {}", self.i)),
                    };
                    let mut tampon = [0u8; 4];
                    octets.extend_from_slice(car.encode_utf8(&mut tampon).as_bytes());
                }
                _ => octets.push(c),
            }
        }
        Ok(String::from_utf8_lossy(&octets).into_owned())
    }

    fn nombre(&mut self) -> Result<Json, String> {
        let debut = self.i;
        while let Some(c) = self.courant() {
            if c.is_ascii_digit() || matches!(c, b'-' | b'+' | b'.' | b'e' | b'E') {
                self.i += 1;
            } else {
                break;
            }
        }
        std::str::from_utf8(&self.o[debut..self.i])
            .ok()
            .and_then(|s| s.parse().ok())
            .map(Json::Nombre)
            .ok_or_else(|| format!("nombre invalide à la position {debut}"))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reponse_hyprland() {
        let j = lire(
            r#"[{"address":"0x5f2a","pid":1234,"class":"firefox","title":"Café 😀 \"x\"",
                "workspace":{"id":2,"name":"2"},"focusHistoryID":0,"grouped":[],"floating":false}]"#,
        )
        .unwrap();
        let f = &j.liste().unwrap()[0];
        assert_eq!(f.champ("pid").unwrap().entier(), Some(1234));
        assert_eq!(f.champ("class").unwrap().texte(), Some("firefox"));
        assert_eq!(f.champ("title").unwrap().texte(), Some("Café 😀 \"x\""));
        assert_eq!(f.champ("workspace").unwrap().champ("id").unwrap().entier(), Some(2));
        assert_eq!(f.champ("focusHistoryID").unwrap().entier(), Some(0));
    }

    #[test]
    fn erreurs() {
        assert!(lire("[1,").is_err());
        assert!(lire("{\"a\" 1}").is_err());
        assert!(lire("[1] x").is_err());
        assert_eq!(lire(" [] ").unwrap(), Json::Liste(vec![]));
        assert_eq!(lire("-1.5e2").unwrap(), Json::Nombre(-150.0));
    }
}
