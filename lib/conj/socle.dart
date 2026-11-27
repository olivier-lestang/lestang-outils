/* Le socle des cartes de conjugaison : temps, teintes, surlignage des
   terminaisons, definitions a sens multiples. Portage fidele de
   web/js/conjugaison/socle.js. SPDX-License-Identifier : MIT. */

/// Casse et accents plies pour la recherche.
String conjNormaliser(String s) {
  final d = s.toLowerCase().runes.toList();
  final out = StringBuffer();
  bool accent = false;
  for (final r in d) {
    if (r >= 0x300 && r <= 0x36f) {
      accent = true;
      continue;
    }
    out.writeCharCode(r);
  }
  return accent ? out.toString() : s.toLowerCase();
}

/// La classe de teinte d un temps, d apres son nom.
/// anterieur 6 ( futur anterieur 7 ), compose 4, plus 5, futur 3,
/// simple 2, imparfait 1, present 0, passe ou parfait 8, sinon 9.
int conjTeinteTemps(String nom) {
  final n = conjNormaliser(nom);
  if (n.contains('anterieur') || n.contains('anterior')) {
    return n.contains('futur') || n.contains('futuro') ? 7 : 6;
  }
  if (n.contains('compose') || n.contains('compuesto') ||
      n.contains('composto') || n.contains('compus') ||
      n.contains('prossimo')) return 4;
  if (n.contains('plus') || n.contains('trapassato') ||
      n.contains('mais-que') || n.contains('mult ca')) return 5;
  if (n.contains('futur') || n.contains('futuro') || n.contains('viitor') ||
      n.contains('przyszły') || n.contains('budoucí')) return 3;
  if (n.contains('simple') || n.contains('simplu') || n.contains('remoto')) {
    return 2;
  }
  if (n.contains('imparfait') || n.contains('imperfecto') ||
      n.contains('imperfetto') || n.contains('imperfect')) return 1;
  if (n.contains('present') || n.contains('présent') ||
      n.contains('präsens') || n.contains('prezent') ||
      n.contains('přítomný') || n.contains('teraźniejszy')) return 0;
  if (n.contains('passe') || n.contains('passé') ||
      n.contains('parfait') || n.contains('perfekt') ||
      n.contains('perfecto') || n.contains('passato') ||
      n.contains('pasado') || n.contains('präteritum') ||
      n.contains('przeszły') || n.contains('minulý') ||
      n.contains('perfect') || n.contains('trecut')) return 8;
  return 9;
}

/// Un temps : nom, etiquettes de personnes, formes, terminaisons brutes.
class Temps {
  final String nom;
  final List<String> pers;
  final List<String> val;
  final List<String>? fin;
  Temps(this.nom, this.pers, this.val, [this.fin]);
}

/// Un mode : son nom et ses temps.
class Mode {
  final String nom;
  final List<Temps> temps;
  Mode(this.nom, this.temps);
}

/// Un token surligne : la terminaison en gras, le reste en noir.
class Piece {
  final String noir; // partie non surlignee, peut etre vide
  final String? fin; // terminal en surlignage, null = rien
  Piece(this.noir, this.fin);
}

Piece conjOlBout(String tok, String fin) {
  if (fin.isEmpty || tok.length < fin.length || !tok.endsWith(fin)) {
    return Piece(tok, null);
  }
  return Piece(tok.substring(0, tok.length - fin.length), fin);
}

/// Un token entier : variantes unies par barre oblique traitees par paire,
/// le clitique de l imperatif apres le tiret reste noir.
List<Piece> conjOlToken(String tok, String fin) {
  if (tok.contains('/') &&
      fin.contains('/') &&
      tok.split('/').length == fin.split('/').length) {
    final tv = tok.split('/'), fv = fin.split('/');
    final out = <Piece>[];
    for (var m = 0; m < tv.length; m++) {
      final p2 = conjOlBout(tv[m], fv[m]);
      if (p2.fin == null) return [Piece(tok, null)];
      out.add(p2);
    }
    return out;
  }
  if (tok.contains('-') && !tok.contains('/')) {
    final st = tok.split('-');
    final b2 = conjOlBout(st[0], fin);
    if (b2.fin != null) {
      final out = <Piece>[b2];
      for (var m = 1; m < st.length; m++) {
        out.add(Piece('-${st[m]}', null));
      }
      return out;
    }
    return [Piece(tok, null)];
  }
  return [conjOlBout(tok, fin)];
}

/// Les pieces surlignees d une forme : la terminal cherchee de droite a
/// gauche dans les tokens, celle de l auxiliaire gagne les composes.
List<Piece> conjTerme(String v, String fin) {
  if (fin.isEmpty) return [Piece(v, null)];
  final toks = v.split(' ');
  for (var j = toks.length - 1; j >= 0; j--) {
    if (toks[j].isEmpty) continue;
    final essai = conjOlToken(toks[j], fin);
    if (essai.first.fin != null) {
      final out = <Piece>[];
      for (var m = 0; m < toks.length; m++) {
        if (m == j) {
          out.addAll(essai);
        } else {
          out.add(Piece(m > 0 ? ' ' + toks[m] : toks[m], null));
        }
      }
      return out;
    }
  }
  return [Piece(v, null)];
}

/// Un sens de definition : etiquette facultative ( registre, domaine )
/// et texte.
class Sens {
  final String etiquette;
  final String texte;
  Sens(this.etiquette, this.texte);
}

/// La definition d un verbe : un ou plusieurs sens, separes par \\u0003,
/// etiquette facultative devant par \\u0004.
List<Sens> conjSens(String blob) {
  return blob.split('\u0003').map((tx) {
    final k = tx.indexOf('\u0004');
    if (k < 0) return Sens('', tx);
    return Sens(tx.substring(0, k), tx.substring(k + 1));
  }).toList();
}

/// Formes pleines par personne : le radical se colle, les variantes unies
/// par barre oblique ; le champ vide reste vide.
List<String> pleinesColler(String rad, List<String> a, int n) {
  final out = List.filled(n, '', growable: false);
  for (var i = 0; i < n; i++) {
    final f = (i < a.length && a[i].isNotEmpty) ? a[i] : '';
    out[i] = f.isEmpty ? '' : f.split('/').map((x) => rad + x).join('/');
  }
  return out;
}

/// Formes pleines anglaises : le champ vide laisse le radical seul.
List<String> pleinesAnglaises(String rad, List<String> a, int n) {
  final out = List.filled(n, '', growable: false);
  for (var i = 0; i < n; i++) {
    final f = (i < a.length && a[i].isNotEmpty) ? a[i] : '';
    out[i] = f.isEmpty ? rad : f.split('/').map((x) => rad + x).join('/');
  }
  return out;
}
