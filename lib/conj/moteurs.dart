/* Les six moteurs de conjugaison, portage fidele des moteurs JavaScript
   du projet ( fichiers .js sous web/js/conjugaison ) : francais, anglais, espagnol,
   allemand, italien, portugais. Donnees du generateur maison,
   SPDX-License-Identifier : MIT. */
import 'dart:math' as math;

import 'socle.dart';

/* ------------------------------------------------------------------jeu */

class JeuConj {
  final List<Map<String, dynamic>> tpls;
  final List<String> verbes;
  final Map<String, int> tplDe;
  final Map<String, String> radDe; // pt, it, de : le radical encode
  final Map<String, List<String>> parties; // de : rad, pp, aux, sep
  final List<String> plies;
  final Map<String, String> defs;
  JeuConj(this.tpls, this.verbes, this.tplDe, this.radDe, this.parties,
      this.plies, this.defs);

  static List<String> _champ(String s) => s.split(',');

  /// Decode les chaines compactes. Les langues a radical encode
  /// ( portuguais, italien, allemand ) portent « verbe:rad[:pp[:aux[:sep]]] ».
  factory JeuConj.depuis(String tplStr, String verbsStr, String defsStr,
      {bool radicaux = false}) {
    final tpls = <Map<String, dynamic>>[];
    for (final l in tplStr.split('\n')) {
      if (l.isEmpty) continue;
      final c = l.split(';');
      final morceaux = c[0].split(':');
      tpls.add({
        'nom': c[0],
        'suffixe': morceaux.length > 1 ? morceaux[1] : c[0],
        'champs': c.sublist(1).map(_champ).toList(),
      });
    }
    final verbes = <String>[], tplDe = <String, int>{}, plies = <String>[];
    final radDe = <String, String>{};
    final parties = <String, List<String>>{};
    var gi = 0;
    for (final grp in verbsStr.split('\n')) {
      for (final v in grp.split(',')) {
        if (v.isEmpty) continue;
        if (radicaux) {
          final c = v.split(':');
          tplDe[c[0]] = gi;
          radDe[c[0]] = c.length > 1 ? c[1] : '';
          parties[c[0]] = c;
          verbes.add(c[0]);
          plies.add(conjNormaliser(c[0]));
        } else {
          tplDe[v] = gi;
          verbes.add(v);
          plies.add(conjNormaliser(v));
        }
      }
      gi++;
    }
    final defs = <String, String>{};
    for (final p in defsStr.split('\u0002')) {
      if (p.isEmpty) continue;
      final k = p.split('\u0001');
      if (k.length == 2 && k[0].isNotEmpty) defs[k[0]] = k[1];
    }
    return JeuConj(tpls, verbes, tplDe, radDe, parties, plies, defs);
  }

  List<String> suggestions(String q) {
    final n = conjNormaliser(q);
    final res = <String>[];
    if (n.isEmpty) return res;
    for (var i = 0; i < verbes.length && res.length < 40; i++) {
      if (plies[i].startsWith(n)) res.add(verbes[i]);
    }
    if (res.length < 8) {
      for (var j = 0; j < verbes.length && res.length < 40; j++) {
        if (plies[j].contains(n) && !res.contains(verbes[j])) {
          res.add(verbes[j]);
        }
      }
    }
    return res;
  }

  final math.Random _hazard = math.Random();
  String hasard() => verbes[_hazard.nextInt(verbes.length)];
}

typedef Tpl = Map<String, dynamic>;

/* ---------------------------------------------------------------FRANCE */

const _ETRE_B = [
  'aller',
  'advenir',
  'apparaître',
  'apparaitre',
  'arriver',
  'décéder',
  'devenir',
  'disconvenir',
  'disparaître',
  'entrer',
  'éclore',
  'mourir',
  'naître',
  'naitre',
  'partir',
  'reparaître',
  'rester',
  'tomber',
  'venir'
];
const _DUAL_B = [
  'demeurer',
  'descendre',
  'monter',
  'passer',
  'rentrer',
  'retourner',
  'sortir'
];
const _PREF = [
  'con',
  'contre',
  'de',
  'dé',
  'dis',
  'inter',
  'par',
  'pré',
  'pro',
  'r',
  're',
  'red',
  'rede',
  'ré',
  'sous',
  'sub',
  'sur'
];
const _PERS_FR = ['je', 'tu', 'il·elle', 'nous', 'vous', 'ils·elles'];
const _PERS_SUB_FR = [
  'que je',
  'que tu',
  "qu’il·qu’elle",
  'que nous',
  'que vous',
  "qu’ils·qu’elles"
];
const _CLIT_FR = ['me', 'te', 'se', 'nous', 'vous', 'se'];
final _VOYELLE = RegExp(r'^[aeiouyéèêàâîôûh]');

bool _retirerPrefixe(String v, List<String> bases) {
  var w = v;
  while (w.isNotEmpty) {
    var coupe = false;
    for (final p in _PREF) {
      if (w.length > p.length && w.startsWith(p)) {
        w = w.substring(p.length);
        coupe = true;
        break;
      }
    }
    if (!coupe) return bases.contains(v);
    if (bases.contains(w)) return true;
  }
  return false;
}

bool familleEtre(String v) =>
    _retirerPrefixe(v, _ETRE_B) || _retirerPrefixe(v, _DUAL_B);
bool familleDouble(String v) => _retirerPrefixe(v, _DUAL_B);

String pronominaliser(String v) => (_VOYELLE.hasMatch(v) ? 's’' : 'se ') + v;

String _elider(String personne, String mot) {
  if (mot.isEmpty || !_VOYELLE.hasMatch(mot)) return personne;
  if (personne == 'je') return 'j’';
  if (personne == 'que je') return 'que j’';
  return personne;
}

String _eliderClitique(String clit, String mot) {
  if ((clit == 'me' || clit == 'te' || clit == 'se') &&
      mot.isNotEmpty &&
      _VOYELLE.hasMatch(mot)) {
    return '${clit.substring(0, 1)}’';
  }
  return clit;
}

class Fr {
  final JeuConj jeu;
  Fr(this.jeu);

  Tpl _modeleDe(String v) => jeu.tpls[jeu.tplDe[v]!];

  List<String> _pleines(String rad, List<String> a, int n) =>
      pleinesColler(rad, a, n);

  Map<String, List<String>> _formes(String v) {
    final tp = _modeleDe(v);
    final rad = v.substring(0, v.length - (tp['suffixe'] as String).length);
    final c = (tp['champs'] as List<List<String>>);
    List<String> c_ext([int i = 0]) => c.length > i ? c[i] : const <String>[];
    return {
      'ind': _pleines(rad, c_ext(0), 6),
      'imp': _pleines(rad, c_ext(1), 6),
      'fut': _pleines(rad, c_ext(2), 6),
      'ps': _pleines(rad, c_ext(3), 6),
      'cond': _pleines(rad, c_ext(4), 6),
      'sub': _pleines(rad, c_ext(5), 6),
      'subi': _pleines(rad, c_ext(6), 6),
      'impe': _pleines(rad, c_ext(7), 3),
      'ppres': _pleines(rad, c_ext(8), 1),
      'pp': _pleines(rad, c_ext(9), 4),
      'finInd': c_ext(0),
      'finImp': c_ext(1),
      'finFut': c_ext(2),
      'finPs': c_ext(3),
      'finCond': c_ext(4),
      'finSub': c_ext(5),
      'finSubi': c_ext(6),
      'finImpe': c_ext(7),
      'finPpres': c_ext(8),
      'finPp': c_ext(9),
    };
  }

  Map<String, List<String>> _auxiliaire(String nom) {
    final v = nom == ':être' ? 'être' : 'avoir';
    Tpl? tp;
    for (final t in jeu.tpls) {
      if (t['nom'] == nom) {
        tp = t;
        break;
      }
    }
    final rad = v.substring(0, v.length - (tp!['suffixe'] as String).length);
    final c = (tp['champs'] as List<List<String>>);
    return {
      'inf': [v],
      'ind': _pleines(rad, c[0], 6),
      'imp': _pleines(rad, c[1], 6),
      'fut': _pleines(rad, c[2], 6),
      'ps': _pleines(rad, c[3], 6),
      'cond': _pleines(rad, c[4], 6),
      'sub': _pleines(rad, c[5], 6),
      'subi': _pleines(rad, c[6], 6),
      'impe': _pleines(rad, c[7], 3),
      'finInd': c[0],
      'finImp': c[1],
      'finFut': c[2],
      'finPs': c[3],
      'finCond': c[4],
      'finSub': c[5],
      'finSubi': c[6],
      'finImpe': c[7],
    };
  }

  String _part(int i, List<String> pp, bool etre) {
    if (!etre) return pp[0];
    final sing = i <= 2;
    final base = pp[sing ? 0 : 1];
    final alt = pp[sing ? 2 : 3];
    if (alt.isNotEmpty && alt != base) return '$base ($alt)';
    return base;
  }

  Temps _rangeesSix(List<String> pers, bool clit, List<String> formes6,
      List<String>? pp, bool etre, List<String> fin) {
    final eti = <String>[], val = <String>[];
    for (var i = 0; i < 6; i++) {
      final fx = i < formes6.length ? formes6[i] : '';
      if (fx.isEmpty) {
        val.add('');
        eti.add(pers[i]);
        continue;
      }
      String f2;
      if (clit) {
        final c = _eliderClitique(_CLIT_FR[i], fx);
        f2 = c == _CLIT_FR[i] ? '$c $fx' : c + fx;
      } else {
        f2 = fx;
      }
      if (pp != null) f2 = '$f2 ${_part(i, pp, etre)}';
      val.add(f2);
      eti.add(_elider(pers[i], f2.split(' ').first));
    }
    return Temps('', eti, val, fin);
  }

  Temps _tenseR(String nom, Temps r) => Temps(nom, r.pers, r.val, r.fin);

  List<String> _rangeesImperatif(
      List<String> impe, bool clit, List<String>? pp, bool etre) {
    final out = <String>[];
    for (var i = 0; i < 3; i++) {
      final fx = i < impe.length ? impe[i] : '';
      if (fx.isEmpty) {
        out.add('');
        continue;
      }
      var cell = fx + (clit ? '-${['toi', 'nous', 'vous'][i]}' : '');
      if (pp != null) {
        cell = '$cell ${_part(i == 0 ? 0 : (i == 1 ? 3 : 4), pp, etre)}';
      }
      out.add(cell);
    }
    return out;
  }

  bool infinitifSeul(String v) {
    final f = _formes(v);
    return [
      ...f['ind']!,
      ...f['imp']!,
      ...f['fut']!,
      ...f['ps']!,
      ...f['cond']!,
      ...f['sub']!,
      ...f['subi']!,
      ...f['impe']!,
      ...f['ppres']!,
      ...f['pp']!
    ].every((x) => x.isEmpty);
  }

  int groupeDe(String v) {
    final vv = v.toLowerCase();
    if (vv.length > 2 && vv.endsWith('er') && vv != 'aller') return 1;
    final f = _formes(vv);
    final ppres = f['ppres']!.isNotEmpty ? f['ppres']![0] : '';
    final pp = f['pp']!.isNotEmpty ? f['pp']![0] : '';
    if (vv.length > 1 &&
        vv.endsWith('ir') &&
        ppres.endsWith('issant') &&
        pp.endsWith('i')) {
      return 2;
    }
    return 3;
  }

  Map<String, String> chapeau(String v, bool clit) {
    final usesEtre = clit || familleEtre(v);
    final dual = !clit && familleDouble(v);
    return {
      'titre': clit ? pronominaliser(v) : v,
      'groupe': groupeDe(v).toString(),
      'auxiliaire': dual ? 'avoir ou être' : (usesEtre ? 'être' : 'avoir'),
    };
  }

  List<Mode> rend(String v, bool clit) {
    final f = _formes(v);
    final usesEtre = clit || familleEtre(v);
    final A = _auxiliaire(usesEtre ? ':être' : ':avoir');
    final per1 = _PERS_FR, per2 = _PERS_SUB_FR;
    final impPer = ['(tu)', '(nous)', '(vous)'];
    const P4 = [
      'masculin singulier',
      'masculin pluriel',
      'féminin singulier',
      'féminin pluriel'
    ];
    final modes = <Mode>[];
    modes.add(Mode('Infinitif', [
      Temps('présent', ['—'], [clit ? pronominaliser(v) : v]),
      Temps('passé', [
        '—'
      ], [
        clit
            ? '${pronominaliser('être')} ${_part(0, f['pp']!, true)}'
            : '${A['inf']![0]} ${_part(0, f['pp']!, usesEtre)}'
      ])
    ]));
    modes.add(Mode('Indicatif', [
      _tenseR('présent',
          _rangeesSix(per1, clit, f['ind']!, null, false, f['finInd']!)),
      _tenseR('imparfait',
          _rangeesSix(per1, clit, f['imp']!, null, false, f['finImp']!)),
      _tenseR('passé simple',
          _rangeesSix(per1, clit, f['ps']!, null, false, f['finPs']!)),
      _tenseR('futur simple',
          _rangeesSix(per1, clit, f['fut']!, null, false, f['finFut']!)),
      _tenseR('passé composé',
          _rangeesSix(per1, clit, A['ind']!, f['pp'], true, A['finInd']!)),
      _tenseR('plus-que-parfait',
          _rangeesSix(per1, clit, A['imp']!, f['pp'], true, A['finImp']!)),
      _tenseR('passé antérieur',
          _rangeesSix(per1, clit, A['ps']!, f['pp'], true, A['finPs']!)),
      _tenseR('futur antérieur',
          _rangeesSix(per1, clit, A['fut']!, f['pp'], true, A['finFut']!)),
    ]));
    modes.add(Mode('Conditionnel', [
      _tenseR('présent',
          _rangeesSix(per1, clit, f['cond']!, null, false, f['finCond']!)),
      _tenseR('passé',
          _rangeesSix(per1, clit, A['cond']!, f['pp'], true, A['finCond']!)),
    ]));
    modes.add(Mode('Subjonctif', [
      _tenseR('présent',
          _rangeesSix(per2, clit, f['sub']!, null, false, f['finSub']!)),
      _tenseR('imparfait',
          _rangeesSix(per2, clit, f['subi']!, null, false, f['finSubi']!)),
      _tenseR('passé',
          _rangeesSix(per2, clit, A['sub']!, f['pp'], true, A['finSub']!)),
      _tenseR('plus-que-parfait',
          _rangeesSix(per2, clit, A['subi']!, f['pp'], true, A['finSubi']!)),
    ]));
    modes.add(Mode('Impératif', [
      Temps('présent', impPer, _rangeesImperatif(f['impe']!, clit, null, false),
          f['finImpe']!),
      Temps(
          'passé',
          impPer,
          clit
              ? ['', '', '']
              : _rangeesImperatif(A['impe']!, false, f['pp'], true),
          A['finImpe']!),
    ]));
    modes.add(Mode('Participe', [
      Temps(
          'présent',
          ['—'],
          [clit ? pronominaliser(f['ppres']![0]) : f['ppres']![0]],
          f['finPpres']!),
      Temps('passé', P4, f['pp']!, f['finPp']!),
    ]));
    return modes;
  }
}

/* --------------------------------------------------------------ANGLAIS */

class En {
  final JeuConj jeu;
  En(this.jeu);
  Tpl _modeleDe(String v) => jeu.tpls[jeu.tplDe[v]!];

  String _une(String rad, String suf) =>
      suf.isEmpty ? '' : suf.split('/').map((x) => rad + x).join('/');

  Map<String, dynamic> formes(String v) {
    final tp = _modeleDe(v);
    final rad = v.substring(0, v.length - (tp['suffixe'] as String).length);
    final c = (tp['champs'] as List<List<String>>);
    final past = pleinesAnglaises(rad, c.length > 1 ? c[1] : const [], 6);
    final ppSuf = c.length > 2 ? c[2].join(',') : '';
    var pp = _une(rad, ppSuf);
    if (pp.isEmpty) pp = past[0];
    return {'past': past, 'pp': pp};
  }

  String preteriteDe(List<String> past) {
    final vues = <String>[];
    for (final p in past) {
      if (!vues.contains(p)) vues.add(p);
    }
    return vues.join('/');
  }

  List<String> voisins(String v) {
    final tri = [...jeu.verbes]..sort();
    final pos = tri.indexOf(v);
    if (pos < 0) return [];
    final deb = pos - 3 < 0 ? 0 : pos - 3;
    final fin = pos + 4 > tri.length ? tri.length : pos + 4;
    return tri.sublist(deb, fin);
  }
}

/* -------------------------------------------------------------ESPAGNOL */

const _PERS_ES = ['yo', 'tú', 'él·ella', 'nosotros', 'vosotros', 'ellos·ellas'];
const _PERS_SUB_ES = [
  'que yo',
  'que tú',
  'que él·ella',
  'que nosotros',
  'que vosotros',
  'que ellos·ellas'
];
const _IMP_PER_ES = [
  '(tú)',
  '(nosotros)',
  '(vosotros)',
  '(usted)',
  '(ustedes)'
];
const _CLIT_ES = ['me', 'te', 'se', 'nos', 'os', 'se'];
const _ORD_IMP_ES = [0, 1, 3, 4, 2, 5];

class Es {
  final JeuConj jeu;
  Es(this.jeu);
  Tpl _modeleDe(String v) => jeu.tpls[jeu.tplDe[v]!];

  String _une(String rad, String suf) =>
      suf.isEmpty ? '' : suf.split('/').map((x) => rad + x).join('/');

  bool pronominal(String v) {
    final tp = _modeleDe(v);
    final suff = tp['suffixe'] as String;
    return suff.length >= 4 && suff.endsWith('se');
  }

  String? baseDe(String v) {
    if (!v.endsWith('rse') || v.length < 5) return null;
    return v.substring(0, v.length - 2);
  }

  Map<String, List<String>> _formes(String v) {
    final tp = _modeleDe(v);
    final rad = v.substring(0, v.length - (tp['suffixe'] as String).length);
    final c = (tp['champs'] as List<List<String>>);
    List<String> champ([int i = 0]) => c.length > i ? c[i] : const <String>[];
    final ppc = champ(10);
    List<String> pp4;
    if (_une(rad, ppc.isNotEmpty ? ppc[0] : '').isNotEmpty) {
      pp4 = ppc.map((x) => _une(rad, x)).toList();
    } else {
      final b = baseDe(v);
      var ok = false;
      var out4 = List.filled(4, '');
      if (b != null && jeu.tplDe.containsKey(b)) {
        final tb = _modeleDe(b);
        final rb = b.substring(0, b.length - (tb['suffixe'] as String).length);
        final cb = (tb['champs'] as List<List<String>>);
        final cbb = cb.length > 10 ? cb[10] : const [''];
        out4 = cbb.map((x) => _une(rb, x)).toList();
        ok = true;
      }
      pp4 = ok ? out4 : List.filled(4, '');
    }
    return {
      'pri': pleinesColler(rad, champ(0), 6),
      'pii': pleinesColler(rad, champ(1), 6),
      'ifi': pleinesColler(rad, champ(2), 6),
      'fti': pleinesColler(rad, champ(3), 6),
      'cni': pleinesColler(rad, champ(4), 6),
      'prs': pleinesColler(rad, champ(5), 6),
      'pis': pleinesColler(rad, champ(6), 6),
      'fts': pleinesColler(rad, champ(7), 6),
      'imp': pleinesColler(rad, champ(8), 5),
      'ger': [champ(9).join(',')],
      'gerBrut': champ(9),
      'pp4': pp4,
      'finPri': champ(0),
    };
  }

  Map<String, List<String>> _auxHaber() {
    final tp = _modeleDe('haber');
    final rad =
        'haber'.substring(0, 'haber'.length - (tp['suffixe'] as String).length);
    final c = (tp['champs'] as List<List<String>>);
    return {
      'pri': pleinesColler(rad, c[0], 6),
      'pii': pleinesColler(rad, c[1], 6),
      'ifi': pleinesColler(rad, c[2], 6),
      'fti': pleinesColler(rad, c[3], 6),
      'cni': pleinesColler(rad, c[4], 6),
      'prs': pleinesColler(rad, c[5], 6),
      'pis': pleinesColler(rad, c[6], 6),
    };
  }

  List<String> _lignes(List<String> formes6, bool clit) {
    final out = <String>[];
    for (var i = 0; i < 6; i++) {
      final fx = i < formes6.length ? formes6[i] : '';
      out.add(fx.isEmpty ? '' : (clit ? '${_CLIT_ES[i]} ' : '') + fx);
    }
    return out;
  }

  List<String> _composes(List<String> aux6, String pp, bool clit) {
    final out = <String>[];
    for (var i = 0; i < 6; i++) {
      final h = i < aux6.length ? aux6[i] : '';
      final suite = h.isEmpty ? '' : '$h $pp';
      out.add(suite.isEmpty ? '' : (clit ? '${_CLIT_ES[i]} ' : '') + suite);
    }
    return out;
  }

  List<String> _imperatif(List<String> imp, bool clit) {
    final out = <String>[];
    for (var i = 0; i < 5; i++) {
      final fx = i < imp.length ? imp[i] : '';
      final c = _ORD_IMP_ES[i];
      out.add(fx.isEmpty ? '' : (clit && c > 0 ? '$fx-${_CLIT_ES[c]}' : fx));
    }
    return out;
  }

  List<Mode> rend(String v) {
    final clit = pronominal(v);
    final f = _formes(v), H = _auxHaber();
    final pp = f['pp4']![0];
    final modes = <Mode>[];
    modes.add(Mode('Infinitif', [
      Temps('présent', ['—'], [v]),
      Temps('parfait', ['—'], [pp.isEmpty ? '' : '${H['pri']![2]} $pp']),
    ]));
    modes.add(Mode('Indicatif', [
      Temps('présent', _PERS_ES, _lignes(f['pri']!, clit), f['finPri']),
      Temps('imparfait', _PERS_ES, _lignes(f['pii']!, clit)),
      Temps('passé simple', _PERS_ES, _lignes(f['ifi']!, clit)),
      Temps('futur simple', _PERS_ES, _lignes(f['fti']!, clit)),
      Temps('passé composé', _PERS_ES, _composes(H['pri']!, pp, clit)),
      Temps('plus-que-parfait', _PERS_ES, _composes(H['pii']!, pp, clit)),
      Temps('passé antérieur', _PERS_ES, _composes(H['ifi']!, pp, clit)),
      Temps('futur antérieur', _PERS_ES, _composes(H['fti']!, pp, clit)),
    ]));
    modes.add(Mode('Conditionnel', [
      Temps('présent', _PERS_ES, _lignes(f['cni']!, clit)),
      Temps('passé', _PERS_ES, _composes(H['cni']!, pp, clit)),
    ]));
    modes.add(Mode('Subjonctif', [
      Temps('présent', _PERS_SUB_ES, _lignes(f['prs']!, clit)),
      Temps('imparfait', _PERS_SUB_ES, _lignes(f['pis']!, clit)),
      Temps('futur (archaïque)', _PERS_SUB_ES, _lignes(f['fts']!, clit)),
      Temps('passé', _PERS_SUB_ES, _composes(H['prs']!, pp, clit)),
      Temps('plus-que-parfait', _PERS_SUB_ES, _composes(H['pis']!, pp, clit)),
    ]));
    modes.add(Mode('Impératif', [
      Temps('présent', _IMP_PER_ES, _imperatif(f['imp']!, clit)),
    ]));
    modes.add(Mode('Participe', [
      Temps(
          'passé',
          const [
            'masculin singulier',
            'masculin pluriel',
            'féminin singulier',
            'féminin pluriel'
          ],
          (f['pp4']!)),
      Temps('présent', ['gérondif'], f['ger']!, f['gerBrut']),
    ]));
    return modes;
  }
}

/* Iberie commune : modeles « nom;P;I;R;F;C;S1;S2;IMP;PP[;AUX] »,
   la marque ! donne la forme entiere, + colle le participe au radical. */
class PleinesIberie {
  final Tpl tp;
  final String rad;
  PleinesIberie(this.tp, this.rad);

  List<String> pleines(List<String> pieces) {
    if (pieces.isEmpty) return [];
    return pieces.map((x) {
      if (x.startsWith('!')) return x.substring(1);
      return rad + x;
    }).toList();
  }

  List<List<String>> get c => (tp['champs'] as List<List<String>>);
}

/* ---------------------------------------------------------------ITALIE */

class It {
  final JeuConj jeu;
  It(this.jeu);

  PleinesIberie fiche(String v) {
    final tp = jeu.tpls[jeu.tplDe[v]!];
    return PleinesIberie(tp, jeu.radDe[v] ?? '');
  }

  String participe(PleinesIberie r, String v) {
    final pp = r.c.length > 8 ? r.c[8].join(',') : '';
    if (pp.startsWith('+')) return '${r.rad}${pp.substring(1)}';
    if (pp.isNotEmpty) return pp;
    if (v.endsWith('are')) return '${r.rad}ato';
    if (v.endsWith('ire')) return '${r.rad}ito';
    return '${r.rad}uto';
  }

  static const _ix = {'P': 0, 'I': 1, 'R': 2, 'F': 3, 'C': 4, 'S1': 5, 'S2': 6};

  List<String> _aux(String nom, String champ) {
    final tp = jeu.tpls[jeu.tplDe[nom]!];
    final r = PleinesIberie(tp, jeu.radDe[nom] ?? '');
    return r.pleines(r.c[_ix[champ]!]);
  }

  List<Mode> rend(String v) {
    final r = fiche(v);
    final pp = participe(r, v);
    final auxChamps = r.c.length > 9 ? r.c[9] : const ['a'];
    final auxNom =
        auxChamps.isNotEmpty && auxChamps[0].contains('e') ? 'essere' : 'avere';
    List<String> aux(String champ) => _aux(auxNom, champ);
    List<String> compose(List<String> a) =>
        a.map((h) => h.isEmpty ? '' : '$h $pp').toList();
    const per1 = ['io', 'tu', 'lui·lei', 'noi', 'voi', 'loro'];
    const per2 = [
      'che io',
      'che tu',
      'che lui·lei',
      'che noi',
      'che voi',
      'che loro'
    ];
    const impPer = ['(tu)', '(noi)', '(voi)', '(Lei)', '(Loro)'];
    Temps simple(String nom, List<String> pieces) => Temps(
        nom,
        per1,
        r.pleines(pieces),
        pieces.isNotEmpty && pieces[0].startsWith('!') ? null : pieces);
    Temps simpleSub(String nom, List<String> pieces) => Temps(
        nom,
        per2,
        r.pleines(pieces),
        pieces.isNotEmpty && pieces[0].startsWith('!') ? null : pieces);

    final modes = <Mode>[];
    modes.add(Mode('Infinito', [
      Temps('présent', ['—'], [v]),
      Temps('passé', ['—'], ['${aux('P')[0]} $pp']),
    ]));
    modes.add(Mode('Indicativo', [
      simple('présent', r.c[0]),
      simple('imperfetto', r.c[1]),
      simple('passato remoto', r.c[2]),
      simple('futuro semplice', r.c[3]),
      Temps('passato prossimo', per1, compose(aux('P'))),
      Temps('trapassato', per1, compose(aux('I'))),
      Temps('futuro anteriore', per1, compose(aux('F'))),
    ]));
    modes.add(Mode('Condizionale', [
      simple('presente', r.c[4]),
      Temps('passato', per1, compose(aux('C'))),
    ]));
    modes.add(Mode('Congiuntivo', [
      simpleSub('presente', r.c[5]),
      simpleSub('imperfetto', r.c[6]),
      Temps('passato', per2, compose(aux('S1'))),
      Temps('trapassato', per2, compose(aux('S2'))),
    ]));
    modes.add(Mode('Imperativo', [
      Temps('presente', impPer, r.pleines(r.c[7])),
    ]));
    modes.add(Mode('Participio', [
      Temps('passé', ['participio passato'], [pp]),
    ]));
    return modes;
  }
}

/* -------------------------------------------------------------PORTUGAIS */

class Pt {
  final JeuConj jeu;
  Pt(this.jeu);

  PleinesIberie fiche(String v) {
    final tp = jeu.tpls[jeu.tplDe[v]!];
    return PleinesIberie(tp, jeu.radDe[v] ?? '');
  }

  static const _ix = {'P': 0, 'I': 1, 'R': 2, 'F': 3, 'C': 4, 'S1': 5, 'S2': 6};

  List<String> _auxTer(String champ) {
    final tp = jeu.tpls[jeu.tplDe['ter']!];
    final r = PleinesIberie(tp, jeu.radDe['ter'] ?? '');
    return r.pleines(r.c[_ix[champ]!]);
  }

  String participe(PleinesIberie r) {
    final pp = r.c.length > 8 ? r.c[8].join(',') : '';
    if (pp.startsWith('!')) return pp.substring(1);
    return '${r.rad}$pp';
  }

  List<Mode> rend(String v) {
    final r = fiche(v);
    final pp = participe(r);
    List<String> aux(String champ) => _auxTer(champ);
    List<String> compose(List<String> a) =>
        a.map((h) => h.isEmpty ? '' : '$h $pp').toList();
    const per1 = ['eu', 'tu', 'ele·ela', 'nós', 'vós', 'eles·elas'];
    const per2 = [
      'que eu',
      'que tu',
      'que ele·ela',
      'que nós',
      'que vós',
      'que eles·elas'
    ];
    const impPer = ['(tu)', '(você)', '(nós)', '(vós)', '(vocês)'];
    Temps simple(String nom, List<String> pieces) => Temps(
        nom,
        per1,
        r.pleines(pieces),
        pieces.isNotEmpty && pieces[0].startsWith('!') ? null : pieces);
    Temps simpleSub(String nom, List<String> pieces) => Temps(
        nom,
        per2,
        r.pleines(pieces),
        pieces.isNotEmpty && pieces[0].startsWith('!') ? null : pieces);

    final modes = <Mode>[];
    modes.add(Mode('Infinitivo', [
      Temps('présent', ['—'], [v]),
      Temps('passé', ['—'], ['${aux('P')[0]} $pp']),
    ]));
    modes.add(Mode('Indicativo', [
      simple('présent', r.c[0]),
      simple('pretérito imperfeito', r.c[1]),
      simple('pretérito perfeito simples', r.c[2]),
      simple('futuro simples', r.c[3]),
      Temps('pretérito mais-que-perfeito', per1, compose(aux('I'))),
      Temps('pretérito perfeito composto', per1, compose(aux('P'))),
      Temps('futuro anterior', per1, compose(aux('F'))),
    ]));
    modes.add(Mode('Condicional', [
      simple('presente', r.c[4]),
      Temps('passado', per1, compose(aux('C'))),
    ]));
    modes.add(Mode('Conjuntivo', [
      simpleSub('presente', r.c[5]),
      simpleSub('pretérito imperfeito', r.c[6]),
      Temps('pretérito perfeito composto', per2, compose(aux('S1'))),
      Temps('pretérito mais-que-perfeito composto', per2, compose(aux('S2'))),
    ]));
    modes.add(Mode('Imperativo', [
      Temps('présent', impPer, r.pleines(r.c[7])),
    ]));
    modes.add(Mode('Particípio', [
      Temps('passé', ['particípio passado'], [pp]),
    ]));
    return modes;
  }
}

/* --------------------------------------------------------------ALLEMAGN */

const _PERS_DE = ['ich', 'du', 'er·sie·es', 'wir', 'ihr', 'sie·Sie'];
const _IMP_PER_DE = ['(du)', '(ihr)', 'Sie'];

class De {
  final JeuConj jeu;
  De(this.jeu);

  /// Formes pleines : la particule separable se colle a la fin.
  List<String> pleines(String rad, List<String> pieces, String sep) {
    if (pieces.isEmpty) return [];
    return pieces
        .map((x) => rad + x + (x.isNotEmpty && sep.isNotEmpty ? ' $sep' : ''))
        .toList();
  }

  List<String> _aux(String nom, int ix) {
    final tp = jeu.tpls[jeu.tplDe[nom]!];
    final c = (tp['champs'] as List<List<String>>);
    return pleines(jeu.radDe[nom] ?? '', c[ix], '');
  }

  List<Mode> rend(String v) {
    final tp = jeu.tpls[jeu.tplDe[v]!];
    final c = (tp['champs'] as List<List<String>>);
    final rad = jeu.radDe[v] ?? '';
    // fiche encodee « verbe:rad:pp:aux[:sep] »
    final p = jeu.parties[v] ?? <String>[v];
    final fic = _FicheDe._(p.length > 2 ? p[2] : '', p.length > 3 ? p[3] : 'h',
        p.length > 4 ? p[4] : '');
    final P = pleines(rad, c[0], fic.sep);
    final R = pleines(rad, c[1], fic.sep);
    final IMP = pleines(rad, c.length > 2 ? c[2] : const [], fic.sep);
    final k2 = c.length > 3 ? c[3].join(',') : 'w';
    final W = k2 == 'w'
        ? _aux('werden', 0).map((x) => '$x $v').toList()
        : pleines(rad, k2.split(','), '');
    final auxNom = fic.aux == 's' ? 'sein' : 'haben';
    final auxK2 = fic.aux == 's'
        ? const ['wäre', 'wärest', 'wäre', 'wären', 'wärt', 'wären']
        : const ['hätte', 'hättest', 'hätte', 'hätten', 'hättet', 'hätten'];
    List<String> compose(List<String> a, String morceau) =>
        a.map((h) => h.isEmpty ? '' : '$h $morceau').toList();

    final modes = <Mode>[];
    modes.add(Mode('Infinitif', [
      Temps('présent', ['—'], [v]),
      Temps(
          'parfait', ['—'], ['${fic.pp} ${fic.aux == 's' ? 'sein' : 'haben'}']),
    ]));
    modes.add(Mode('Indicatif (Indikativ)', [
      Temps('présent', _PERS_DE, P),
      Temps('prétérit', _PERS_DE, R),
      Temps('parfait', _PERS_DE, compose(_aux(auxNom, 0), fic.pp)),
      Temps('plus-que-parfait', _PERS_DE, compose(_aux(auxNom, 1), fic.pp)),
      Temps('futur', _PERS_DE, compose(_aux('werden', 0), v)),
      Temps(
          'futur antérieur',
          _PERS_DE,
          compose(_aux('werden', 0),
              '${fic.pp} ${fic.aux == 's' ? 'sein' : 'haben'}')),
    ]));
    modes.add(Mode('Konjunktiv II', [
      Temps('présent', _PERS_DE, W),
      Temps('passé', _PERS_DE, compose(auxK2, fic.pp)),
    ]));
    modes.add(Mode('Impératif', [
      Temps('présent', _IMP_PER_DE, IMP),
    ]));
    modes.add(Mode('Participe', [
      Temps('parfait', ['Partizip II'], [fic.pp]),
    ]));
    return modes;
  }
}

class _FicheDe {
  final String pp;
  final String aux;
  final String sep;
  _FicheDe._(this.pp, this.aux, this.sep);
}

/* ------------------------------------------------ facade par langue ----- */

class PlanchesConjug {
  final String langue;
  final JeuConj jeu;
  final Set<String> duWiktionary; // verbes dont la source est le Wiktionary
  final Fr fr;
  final En en;
  final Es es;
  final It it;
  final Pt pt;
  final De de;
  final Pl? pl;
  final Cs? cs;

  PlanchesConjug(this.langue, this.jeu, this.duWiktionary,
      [Map<String, SlTok>? toks])
      : fr = Fr(jeu),
        en = En(jeu),
        es = Es(jeu),
        it = It(jeu),
        pt = Pt(jeu),
        de = De(jeu),
        pl = langue == 'pl' ? Pl(jeu, toks ?? {}) : null,
        cs = langue == 'cs' ? Cs(jeu, toks ?? {}) : null;

  static const _radicaux = {'de': true, 'it': true, 'pt': true};

  factory PlanchesConjug.depuis(String langue, String tplStr,
      String verbsStr, String defsStr, String vsrcStr) {
    if (langue == 'pl' || langue == 'cs') {
      final noms = <String>[], toks = <String, SlTok>{};
      for (final grp in verbsStr.split('\n')) {
        for (final tok in grp.split(',')) {
          if (tok.isEmpty) continue;
          final c = tok.split(':');
          noms.add(c[0]);
          toks[c[0]] = SlTok(c);
        }
      }
      final defs = <String, String>{};
      for (final part in defsStr.split('\u0002')) {
        if (part.isEmpty) continue;
        final k = part.split('\u0001');
        if (k.length == 2 && k[0].isNotEmpty) defs[k[0]] = k[1];
      }
      final tplDe = <String, int>{}, plies = <String>[];
      for (var i = 0; i < noms.length; i++) {
        tplDe[noms[i]] = i;
        plies.add(conjNormaliser(noms[i]));
      }
      final jeu = JeuConj(const [], noms, tplDe, const {}, const {},
          plies, defs);
      final duWikit = <String>{};
      for (final l in vsrcStr.split('\n')) {
        if (l.isNotEmpty) duWikit.add(l);
      }
      return PlanchesConjug(langue, jeu, duWikit, toks);
    }
    final jeu = JeuConj.depuis(tplStr, verbsStr, defsStr,
        radicaux: _radicaux[langue] ?? false);
    final duWikit = <String>{};
    for (final l in vsrcStr.split('\n')) {
      if (l.isNotEmpty) duWikit.add(l);
    }
    return PlanchesConjug(langue, jeu, duWikit);
  }

  /// La source de la conjugaison d un verbe : 'w' Wiktionary (CC BY-SA 4.0),
  /// 'g' generateur maison du projet (MIT, donnees du domaine public).
  String sourceVerbe(String v) => duWiktionary.contains(v) ? 'w' : 'g';

  bool connait(String v) => jeu.tplDe.containsKey(v);

  /// Le titre affiche du verbe.
  String titre(String v, {bool clit = false}) =>
      langue == 'fr' && clit ? pronominaliser(v) : v;

  Map<String, String> chapeau(String v, {bool clit = false}) {
    final out = <String, String>{'titre': titre(v, clit: clit)};
    if (langue == 'fr') out.addAll(fr.chapeau(v, clit));
    return out;
  }

  List<Sens> definition(String v) {
    final d = jeu.defs[v];
    return d == null ? const [] : conjSens(d);
  }

  List<Mode> rend(String v, {bool clit = false}) {
    switch (langue) {
      case 'fr':
        return fr.rend(v, clit);
      case 'en':
        return const [];
      case 'es':
        return es.rend(v);
      case 'de':
        return de.rend(v);
      case 'it':
        return it.rend(v);
      case 'pt':
        return pt.rend(v);
      case 'pl':
        return pl?.rend(v) ?? const [];
      case 'cs':
        return cs?.rend(v) ?? const [];
    }
    return const [];
  }

  /// La grille anglaise : infinitif, preterit, participe, sept voisines.
  List<Map<String, String>> grilleEn(String v) {
    final out = <Map<String, String>>[];
    for (final w in en.voisins(v)) {
      final f = en.formes(w);
      out.add({
        'verbe': w,
        'preterit': en.preteriteDe(f['past'] as List<String>),
        'pp': f['pp'] as String
      });
    }
    return out;
  }

  bool infinitifSeul(String v) => langue == 'fr' && fr.infinitifSeul(v);
}


/* ------------------------------------------------------------------pl, cs */

/* Polonais et tcheque : moteurs dedies, donnees verifiees depuis le
   Wiktionary (kaikki.org, CC BY-SA 4.0) ; phrases calculees sur l appareil.
   Token : nom:s1[:s3]:p3:W:V:imp2:aspect ; formes additionnelles calculees.
   SPDX-License-Identifier : MIT. */

class SlTok {
  final List<String> c;
  SlTok(this.c);
  String get nom => c[0];
}

class Pl {
  final JeuConj jeu;
  final Map<String, SlTok> toks;
  Pl(this.jeu, this.toks);

  static const _per = ['ja', 'ty', 'on·ona', 'my', 'wy', 'oni'];
  static const _perP = [
    'ja m.', 'ja f.', 'ty m.', 'ty f.', 'on', 'ona', 'ono',
    'my m.', 'my n.', 'wy m.', 'wy n.', 'oni', 'one'
  ];
  static const _perImp = ['ty', 'my', 'wy'];

  static String _ortho(String w) {
    return w
        .replaceAll('ge', 'że')
        .replaceAll('ke', 'cze')
        .replaceAll('de', 'dzie')
        .replaceAll('te', 'cie');
  }

  static List<String> _present(SlTok t) {
    final s1 = t.c[1], p3 = t.c[2];
    final stem = s1.endsWith('ę') || s1.endsWith('m') ? s1.substring(0, s1.length - 1) : s1;
    final voy = stem.isNotEmpty && 'aeiyouą'.contains(stem[stem.length - 1]);
    String s2, s3, p1, p2;
    if (voy) {
      s2 = stem + 'sz';
      s3 = stem;
      p1 = stem + 'my';
      p2 = stem + 'cie';
    } else {
      final der = stem[stem.length - 1];
      final eserie = der == 'd' || der == 't' || der == 'k' || der == 'g' ||
          der == 'j' || der == 'ł' ||
          (stem.length > 1 &&
              const ['sz', 'ż', 'cz', 'rz']
                  .contains(stem.substring(stem.length - 2)));
      if (eserie) {
        s2 = _ortho(stem + 'esz');
        s3 = _ortho(stem + 'e');
        p1 = _ortho(stem + 'emy');
        p2 = _ortho(stem + 'ecie');
      } else {
        s2 = stem + 'isz';
        s3 = stem + 'i';
        p1 = stem + 'imy';
        p2 = stem + 'icie';
      }
    }
    return [s1, s2, s3, p1, p2, p3];
  }

  static List<String> _passe(SlTok t) {
    final w = t.c[3], v = t.c[4];
    final base = w.substring(0, w.length - 1); // sans le ł final
    final nv = base + 'ły';
    return [
      base + 'łem', base + 'łam', base + 'łeś', base + 'łaś',
      w, w + 'a', w + 'o',
      v + 'śmy', nv + 'śmy', v + 'ście', nv + 'ście', v, nv
    ];
  }

  static List<String> _cond(SlTok t) {
    final w = t.c[3], v = t.c[4];
    final nv = w.substring(0, w.length - 1) + 'ły';
    return [
      w + 'bym', w + 'abym', w + 'byś', w + 'abyś', w + 'by', w + 'aby', w + 'oby',
      v + 'byśmy', nv + 'byśmy', v + 'byście', nv + 'byście', v + 'by', nv + 'by'
    ];
  }

  // Suffixes et indices du conditionnel (participe passé + bym, byś...).
  static const _condSuf = [
    'bym', 'bym', 'byś', 'byś', 'by', 'by', 'by', 'byśmy', 'byśmy',
    'byście', 'byście', 'by', 'by'
  ];
  static const _condIdx = [4, 5, 4, 5, 4, 5, 6, 11, 12, 11, 12, 11, 12];

  /// Verbe exceptionnel (t.c[1]=='E') : formes verbatim du Wiktionary.
  static List<Mode> _rendEx(SlTok t) {
    final pres = t.c[2].split(';');
    final past = t.c[3].split(';');
    final imp = t.c[4].split(';');
    final asp = t.c[5];
    final mode = <Mode>[];
    final ind = <Temps>[];
    if (asp == 'i') {
      ind.add(Temps('présent', _per, pres));
      ind.add(Temps('futur', _per,
          ['będę', 'będziesz', 'będzie', 'będziemy', 'będziecie', 'będą']
              .map((b) => '$b ${t.nom}').toList()));
    } else {
      ind.add(Temps('futur', _per, pres));
    }
    ind.add(Temps('passé', _perP, past));
    mode.add(Mode('Indicatif', ind));
    final cond = [
      for (var i = 0; i < 13; i++) '${past[_condIdx[i]]}${_condSuf[i]}'
    ];
    mode.add(Mode('Conditionnel', [Temps('présent', _perP, cond)]));
    if (imp.any((x) => x.isNotEmpty)) {
      mode.add(Mode('Impératif', [Temps('présent', _perImp, imp)]));
    }
    return mode;
  }

  List<Mode> rend(String v) {
    if (v == 'być') return _byc;
    final t = toks[v];
    if (t == null || v == 'iść') return v == 'iść' ? _isc : const [];
    if (t.c.length > 1 && t.c[1] == 'E') return _rendEx(t);
    final asp = t.c[6];
    final mode = <Mode>[];
    final pres = _present(t);
    final ind = <Temps>[];
    if (asp == 'i') {
      ind.add(Temps('présent', _per, pres));
      ind.add(Temps('futur', _per,
          ['będę', 'będziesz', 'będzie', 'będziemy', 'będziecie', 'będą']
              .map((b) => '$b $v').toList()));
    } else {
      ind.add(Temps('futur', _per, pres));
    }
    ind.add(Temps('passé', _perP, _passe(t)));
    mode.add(Mode('Indicatif', ind));
    mode.add(Mode('Conditionnel', [Temps('présent', _perP, _cond(t))]));
    final imp2 = t.c[5];
    mode.add(Mode('Impératif', [
      Temps('présent', _perImp, [imp2, imp2 + 'my', imp2 + 'cie'])
    ]));
    return mode;
  }

  static List<Mode> get _byc {
    return [
      Mode('Indicatif', [
        Temps('présent', _per,
            const ['jestem', 'jesteś', 'jest', 'jesteśmy', 'jesteście', 'są']),
        Temps('futur', _per,
            const ['będę', 'będziesz', 'będzie', 'będziemy', 'będziecie', 'będą']),
        Temps('passé', _perP, const [
          'byłem', 'byłam', 'byłeś', 'byłaś', 'był', 'była', 'było',
          'byliśmy', 'byłyśmy', 'byliście', 'byłyście', 'byli', 'były'
        ]),
      ]),
      Mode('Conditionnel', [Temps('présent', _perP, const [
        'byłbym', 'byłabym', 'byłbyś', 'byłabyś', 'byłby', 'byłaby', 'byłoby',
        'bylibyśmy', 'byłybyśmy', 'bylibyście', 'byłybyście', 'byliby', 'byłyby'
      ])]),
      Mode('Impératif', [Temps(
          'présent', _perImp, const ['bądź', 'bądźmy', 'bądźcie'])]),
    ];
  }

  static List<Mode> get _isc {
    return [
      Mode('Indicatif', [
        Temps('présent', _per,
            const ['idę', 'idziesz', 'idzie', 'idziemy', 'idziecie', 'idą']),
        Temps('futur', _per, const [
          'będę iść', 'będziesz iść', 'będzie iść',
          'będziemy iść', 'będziecie iść', 'będą iść'
        ]),
        Temps('passé', _perP, const [
          'szedłem', 'szłam', 'szedłeś', 'szłaś', 'szedł', 'szła', 'szło',
          'szliśmy', 'szłyśmy', 'szliście', 'szłyście', 'szli', 'szły'
        ]),
      ]),
      Mode('Conditionnel', [Temps('présent', _perP, const [
        'szedłbym', 'szłabym', 'szedłbyś', 'szłabyś', 'szedłby', 'szłaby', 'szłoby',
        'szlibyśmy', 'szłybyśmy', 'szlibyście', 'szłybyście', 'szliby', 'szłyby'
      ])]),
      Mode('Impératif', [Temps(
          'présent', _perImp, const ['idź', 'idźmy', 'idźcie'])]),
    ];
  }
}

class Cs {
  final JeuConj jeu;
  final Map<String, SlTok> toks;
  Cs(this.jeu, this.toks);

  static const _per = ['já', 'ty', 'on·ona', 'my', 'vy', 'oni'];
  static const _perP = [
    'já m.', 'já f.', 'ty m.', 'ty f.', 'on', 'ona', 'ono',
    'my m.', 'my n.', 'vy m.', 'vy n.', 'oni', 'ony'
  ];
  static const _perImp = ['ty', 'my', 'vy'];

  static List<String> _present(SlTok t) {
    final s1 = t.c[1], s3 = t.c[2], p3 = t.c[3];
    return [s1, s3 + 'š', s3, s3 + 'me', s3 + 'te', p3];
  }

  static List<String> _passe(SlTok t) {
    final w = t.c[4], v = t.c[5];
    final base = w.substring(0, w.length - 1); // sans le l final
    final nv = v.substring(0, v.length - 1) + 'y';
    return [
      '$w jsem', '$base la jsem', '$w jsi', '$base la jsi',
      w, '$base la', '$base lo',
      '$v jsme', '$nv jsme', '$v jste', '$nv jste', v, nv
    ];
  }

  /// Verbe exceptionnel (t.c[1]=='E') : indicatif verbatim du Wiktionary,
  /// passe et conditionnel construits depuis W et V, imperatif verbatim
  /// (parfois absent : muset n a pas d imperatif).
  static List<Mode> _rendEx(SlTok t) {
    final pres = t.c[2].split(';');
    final w = t.c[3], v = t.c[4];
    final imp = t.c[5].split(';');
    final asp = t.c[6];
    final synth = SlTok(['', '', '', '', w, v, '', '']);
    final mode = <Mode>[];
    final ind = <Temps>[];
    if (asp == 'i') {
      ind.add(Temps('présent', _per, pres));
      ind.add(Temps('futur', _per,
          ['budu', 'budeš', 'bude', 'budeme', 'budete', 'budou']
              .map((b) => '$b ${t.nom}').toList()));
    } else {
      ind.add(Temps('futur', _per, pres));
    }
    ind.add(Temps('passé', _perP, _passe(synth)));
    mode.add(Mode('Indicatif', ind));
    mode.add(Mode('Conditionnel', [Temps('présent', _perP, _cond(synth))]));
    if (imp.any((x) => x.isNotEmpty)) {
      mode.add(Mode('Impératif', [Temps('présent', _perImp, imp)]));
    }
    return mode;
  }

  static List<String> _cond(SlTok t) {
    final w = t.c[4], v = t.c[5];
    final base = w.substring(0, w.length - 1);
    final nv = v.substring(0, v.length - 1) + 'y';
    return [
      '$w bych', '$base la bych', '$w bys', '$base la bys',
      '$w by', '$base la by', '$base lo by',
      '$v bychom', '$nv bychom', '$v byste', '$nv byste', '$v by', '$nv by'
    ];
  }

  List<Mode> rend(String v) {
    if (v == 'být') return _byt;
    final t = toks[v];
    if (t == null) return const [];
    if (t.c.length > 1 && t.c[1] == 'E') return _rendEx(t);
    final asp = t.c[7];
    final mode = <Mode>[];
    final pres = _present(t);
    final ind = <Temps>[];
    if (asp == 'i') {
      ind.add(Temps('présent', _per, pres));
      ind.add(Temps('futur', _per,
          ['budu', 'budeš', 'bude', 'budeme', 'budete', 'budou']
              .map((b) => '$b $v').toList()));
    } else {
      ind.add(Temps('futur', _per, pres));
    }
    ind.add(Temps('passé', _perP, _passe(t)));
    mode.add(Mode('Indicatif', ind));
    mode.add(Mode('Conditionnel', [Temps('présent', _perP, _cond(t))]));
    final imp2 = t.c[6];
    String i1, i2;
    if (imp2.endsWith('i')) {
      i1 = imp2.substring(0, imp2.length - 1) + 'ěme';
      i2 = imp2.substring(0, imp2.length - 1) + 'ěte';
    } else {
      i1 = imp2 + 'me';
      i2 = imp2 + 'te';
    }
    mode.add(Mode('Impératif',
        [Temps('présent', _perImp, [imp2, i1, i2])]));
    return mode;
  }

  static List<Mode> get _byt {
    return [
      Mode('Indicatif', [
        Temps('présent', _per,
            const ['jsem', 'jsi', 'je', 'jsme', 'jste', 'jsou']),
        Temps('futur', _per,
            const ['budu', 'budeš', 'bude', 'budeme', 'budete', 'budou']),
        Temps('passé', _perP, const [
          'byl jsem', 'byla jsem', 'byl jsi', 'byla jsi',
          'byl', 'byla', 'bylo',
          'byli jsme', 'byly jsme', 'byli jste', 'byly jste', 'byli', 'byly'
        ]),
      ]),
      Mode('Conditionnel', [Temps('présent', _perP, const [
        'byl bych', 'byla bych', 'byl bys', 'byla bys',
        'byl by', 'byla by', 'bylo by',
        'byli bychom', 'byly bychom', 'byli byste', 'byly byste', 'byli by', 'byly by'
      ])]),
      Mode('Impératif', [Temps(
          'présent', _perImp, const ['buď', 'buďme', 'buďte'])]),
    ];
  }
}
