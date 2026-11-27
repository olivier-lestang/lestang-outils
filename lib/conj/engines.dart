/* The six conjugation engines, faithful port of the JavaScript engines
   of the project ( .js files under web/js/conjugaison ): french,
   english, spanish, german, italian, portuguese. Data of the
   home-made generator, SPDX-License-Identifier: MIT. */
import 'dart:math' as math;

import 'core.dart';

/* ------------------------------------------------------------------set */

class ConjSet {
  final List<Map<String, dynamic>> tpls;
  final List<String> verbs;
  final Map<String, int> tplOf;
  final Map<String, String> stemOf; // pt, it, de: the encoded stem
  final Map<String, List<String>> parts; // de: stem, pp, aux, sep
  final List<String> folds;
  final Map<String, String> defs;
  ConjSet(this.tpls, this.verbs, this.tplOf, this.stemOf, this.parts,
      this.folds, this.defs);

  static List<String> _field(String s) => s.split(',');

  /// Decodes the compact strings. The languages with an encoded stem
  /// ( portuguese, italian, german ) carry "verb:stem[:pp[:aux[:sep]]]".
  factory ConjSet.from(String tplStr, String verbsStr, String defsStr,
      {bool stems = false}) {
    final tpls = <Map<String, dynamic>>[];
    for (final l in tplStr.split('\n')) {
      if (l.isEmpty) continue;
      final c = l.split(';');
      final chunks = c[0].split(':');
      tpls.add({
        'nom': c[0],
        'suffixe': chunks.length > 1 ? chunks[1] : c[0],
        'champs': c.sublist(1).map(_field).toList(),
      });
    }
    final verbs = <String>[], tplOf = <String, int>{}, folds = <String>[];
    final stemOf = <String, String>{};
    final parts = <String, List<String>>{};
    var gi = 0;
    for (final grp in verbsStr.split('\n')) {
      for (final v in grp.split(',')) {
        if (v.isEmpty) continue;
        if (stems) {
          final c = v.split(':');
          tplOf[c[0]] = gi;
          stemOf[c[0]] = c.length > 1 ? c[1] : '';
          parts[c[0]] = c;
          verbs.add(c[0]);
          folds.add(conjNormalize(c[0]));
        } else {
          tplOf[v] = gi;
          verbs.add(v);
          folds.add(conjNormalize(v));
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
    return ConjSet(tpls, verbs, tplOf, stemOf, parts, folds, defs);
  }

  List<String> suggest(String q) {
    final n = conjNormalize(q);
    final res = <String>[];
    if (n.isEmpty) return res;
    /* the exact match goes first: Enter or Tab pick the typed word,
       not the next one */
    for (var i = 0; i < verbs.length; i++) {
      if (folds[i] == n) res.add(verbs[i]);
    }
    for (var i = 0; i < verbs.length && res.length < 40; i++) {
      if (folds[i].startsWith(n) && !res.contains(verbs[i])) {
        res.add(verbs[i]);
      }
    }
    if (res.length < 8) {
      for (var j = 0; j < verbs.length && res.length < 40; j++) {
        if (folds[j].contains(n) && !res.contains(verbs[j])) {
          res.add(verbs[j]);
        }
      }
    }
    return res;
  }

  final math.Random _hazard = math.Random();
  String randomVerb() => verbs[_hazard.nextInt(verbs.length)];
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
final _VOWEL = RegExp(r'^[aeiouyéèêàâîôûh]');

bool _stripPrefix(String v, List<String> bases) {
  var w = v;
  while (w.isNotEmpty) {
    var cut = false;
    for (final p in _PREF) {
      if (w.length > p.length && w.startsWith(p)) {
        w = w.substring(p.length);
        cut = true;
        break;
      }
    }
    if (!cut) return bases.contains(v);
    if (bases.contains(w)) return true;
  }
  return false;
}

bool etreFamily(String v) =>
    _stripPrefix(v, _ETRE_B) || _stripPrefix(v, _DUAL_B);
bool dualFamily(String v) => _stripPrefix(v, _DUAL_B);

String pronominalize(String v) => (_VOWEL.hasMatch(v) ? 's’' : 'se ') + v;

String _elide(String person, String word) {
  if (word.isEmpty || !_VOWEL.hasMatch(word)) return person;
  if (person == 'je') return 'j’';
  if (person == 'que je') return 'que j’';
  return person;
}

String _elideClitic(String clitic, String word) {
  if ((clitic == 'me' || clitic == 'te' || clitic == 'se') &&
      word.isNotEmpty &&
      _VOWEL.hasMatch(word)) {
    return '${clitic.substring(0, 1)}’';
  }
  return clitic;
}

class Fr {
  final ConjSet set;
  Fr(this.set);

  Tpl _modelOf(String v) => set.tpls[set.tplOf[v]!];

  List<String> _full(String stem, List<String> a, int n) =>
      glueFullForms(stem, a, n);

  Map<String, List<String>> _forms(String v) {
    final tp = _modelOf(v);
    final stem = v.substring(0, v.length - (tp['suffixe'] as String).length);
    final c = (tp['champs'] as List<List<String>>);
    List<String> ext([int i = 0]) =>
        c.length > i ? c[i] : const <String>[];
    return {
      'ind': _full(stem, ext(0), 6),
      'imp': _full(stem, ext(1), 6),
      'fut': _full(stem, ext(2), 6),
      'ps': _full(stem, ext(3), 6),
      'cond': _full(stem, ext(4), 6),
      'sub': _full(stem, ext(5), 6),
      'subi': _full(stem, ext(6), 6),
      'impe': _full(stem, ext(7), 3),
      'ppres': _full(stem, ext(8), 1),
      'pp': _full(stem, ext(9), 4),
      'finInd': ext(0),
      'finImp': ext(1),
      'finFut': ext(2),
      'finPs': ext(3),
      'finCond': ext(4),
      'finSub': ext(5),
      'finSubi': ext(6),
      'finImpe': ext(7),
      'finPpres': ext(8),
      'finPp': ext(9),
    };
  }

  Map<String, List<String>> _auxiliary(String name) {
    final v = name == ':être' ? 'être' : 'avoir';
    Tpl? tp;
    for (final t in set.tpls) {
      if (t['nom'] == name) {
        tp = t;
        break;
      }
    }
    final stem = v.substring(0, v.length - (tp!['suffixe'] as String).length);
    final c = (tp['champs'] as List<List<String>>);
    return {
      'inf': [v],
      'ind': _full(stem, c[0], 6),
      'imp': _full(stem, c[1], 6),
      'fut': _full(stem, c[2], 6),
      'ps': _full(stem, c[3], 6),
      'cond': _full(stem, c[4], 6),
      'sub': _full(stem, c[5], 6),
      'subi': _full(stem, c[6], 6),
      'impe': _full(stem, c[7], 3),
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

  Tense _rowsSix(List<String> pers, bool clitic, List<String> forms6,
      List<String>? pp, bool etre, List<String> fin) {
    final labels = <String>[], vals = <String>[];
    for (var i = 0; i < 6; i++) {
      final fx = i < forms6.length ? forms6[i] : '';
      if (fx.isEmpty) {
        vals.add('');
        labels.add(pers[i]);
        continue;
      }
      String f2;
      if (clitic) {
        final c = _elideClitic(_CLIT_FR[i], fx);
        f2 = c == _CLIT_FR[i] ? '$c $fx' : c + fx;
      } else {
        f2 = fx;
      }
      if (pp != null) f2 = '$f2 ${_part(i, pp, etre)}';
      vals.add(f2);
      labels.add(_elide(pers[i], f2.split(' ').first));
    }
    return Tense('', labels, vals, fin);
  }

  Tense _renamed(String name, Tense r) =>
      Tense(name, r.pers, r.val, r.end);

  List<String> _imperativeRows(
      List<String> impe, bool clitic, List<String>? pp, bool etre) {
    final out = <String>[];
    for (var i = 0; i < 3; i++) {
      final fx = i < impe.length ? impe[i] : '';
      if (fx.isEmpty) {
        out.add('');
        continue;
      }
      var cell = fx + (clitic ? '-${['toi', 'nous', 'vous'][i]}' : '');
      if (pp != null) {
        cell = '$cell ${_part(i == 0 ? 0 : (i == 1 ? 3 : 4), pp, etre)}';
      }
      out.add(cell);
    }
    return out;
  }

  bool infinitiveOnly(String v) {
    final f = _forms(v);
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

  int groupOf(String v) {
    final vv = v.toLowerCase();
    if (vv.length > 2 && vv.endsWith('er') && vv != 'aller') return 1;
    final f = _forms(vv);
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

  Map<String, String> header(String v, bool clitic) {
    final usesEtre = clitic || etreFamily(v);
    final dual = !clitic && dualFamily(v);
    return {
      'titre': clitic ? pronominalize(v) : v,
      'groupe': groupOf(v).toString(),
      'auxiliaire': dual ? 'avoir ou être' : (usesEtre ? 'être' : 'avoir'),
    };
  }

  List<Mood> render(String v, bool clitic) {
    final f = _forms(v);
    final usesEtre = clitic || etreFamily(v);
    final A = _auxiliary(usesEtre ? ':être' : ':avoir');
    final per1 = _PERS_FR, per2 = _PERS_SUB_FR;
    final impPer = ['(tu)', '(nous)', '(vous)'];
    const P4 = [
      'masculin singulier',
      'masculin pluriel',
      'féminin singulier',
      'féminin pluriel'
    ];
    final moods = <Mood>[];
    moods.add(Mood('Infinitif', [
      Tense('présent', ['—'], [clitic ? pronominalize(v) : v]),
      Tense('passé', [
        '—'
      ], [
        clitic
            ? '${pronominalize('être')} ${_part(0, f['pp']!, true)}'
            : '${A['inf']![0]} ${_part(0, f['pp']!, usesEtre)}'
      ], [
        f['finPp']!.isNotEmpty ? f['finPp']![0] : ''
      ])
    ]));
    moods.add(Mood('Indicatif', [
      _renamed('présent',
          _rowsSix(per1, clitic, f['ind']!, null, false, f['finInd']!)),
      _renamed('imparfait',
          _rowsSix(per1, clitic, f['imp']!, null, false, f['finImp']!)),
      _renamed('passé simple',
          _rowsSix(per1, clitic, f['ps']!, null, false, f['finPs']!)),
      _renamed('futur simple',
          _rowsSix(per1, clitic, f['fut']!, null, false, f['finFut']!)),
      _renamed('passé composé',
          _rowsSix(per1, clitic, A['ind']!, f['pp'], true, A['finInd']!)),
      _renamed('plus-que-parfait',
          _rowsSix(per1, clitic, A['imp']!, f['pp'], true, A['finImp']!)),
      _renamed('passé antérieur',
          _rowsSix(per1, clitic, A['ps']!, f['pp'], true, A['finPs']!)),
      _renamed('futur antérieur',
          _rowsSix(per1, clitic, A['fut']!, f['pp'], true, A['finFut']!)),
    ]));
    moods.add(Mood('Conditionnel', [
      _renamed('présent',
          _rowsSix(per1, clitic, f['cond']!, null, false, f['finCond']!)),
      _renamed('passé',
          _rowsSix(per1, clitic, A['cond']!, f['pp'], true, A['finCond']!)),
    ]));
    moods.add(Mood('Subjonctif', [
      _renamed('présent',
          _rowsSix(per2, clitic, f['sub']!, null, false, f['finSub']!)),
      _renamed('imparfait',
          _rowsSix(per2, clitic, f['subi']!, null, false, f['finSubi']!)),
      _renamed('passé',
          _rowsSix(per2, clitic, A['sub']!, f['pp'], true, A['finSub']!)),
      _renamed('plus-que-parfait',
          _rowsSix(per2, clitic, A['subi']!, f['pp'], true, A['finSubi']!)),
    ]));
    moods.add(Mood('Impératif', [
      Tense('présent', impPer,
          _imperativeRows(f['impe']!, clitic, null, false), f['finImpe']!),
      Tense(
          'passé',
          impPer,
          clitic
              ? ['', '', '']
              : _imperativeRows(A['impe']!, false, f['pp'], true),
          A['finImpe']!),
    ]));
    moods.add(Mood('Participe', [
      Tense(
          'présent',
          ['—'],
          [clitic ? pronominalize(f['ppres']![0]) : f['ppres']![0]],
          f['finPpres']!),
      Tense('passé', P4, f['pp']!, f['finPp']!),
    ]));
    return moods;
  }
}

/* --------------------------------------------------------------ENGLISH */

class En {
  final ConjSet set;
  En(this.set);
  Tpl _modelOf(String v) => set.tpls[set.tplOf[v]!];

  String _one(String stem, String suf) =>
      suf.isEmpty ? '' : suf.split('/').map((x) => stem + x).join('/');

  Map<String, dynamic> forms(String v) {
    final tp = _modelOf(v);
    final stem = v.substring(0, v.length - (tp['suffixe'] as String).length);
    final c = (tp['champs'] as List<List<String>>);
    final past = englishFullForms(stem, c.length > 1 ? c[1] : const [], 6);
    final ppSuf = c.length > 2 ? c[2].join(',') : '';
    var pp = _one(stem, ppSuf);
    if (pp.isEmpty) pp = past[0];
    return {'past': past, 'pp': pp};
  }

  String preteriteOf(List<String> past) {
    final seen = <String>[];
    for (final p in past) {
      if (!seen.contains(p)) seen.add(p);
    }
    return seen.join('/');
  }

  List<String> neighbours(String v) {
    final sorted = [...set.verbs]..sort();
    final pos = sorted.indexOf(v);
    if (pos < 0) return [];
    final start = pos - 3 < 0 ? 0 : pos - 3;
    final end = pos + 4 > sorted.length ? sorted.length : pos + 4;
    return sorted.sublist(start, end);
  }
}

/* ---------------------------------------------------------------SPAIN */

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
  final ConjSet set;
  Es(this.set);
  Tpl _modelOf(String v) => set.tpls[set.tplOf[v]!];

  String _one(String stem, String suf) =>
      suf.isEmpty ? '' : suf.split('/').map((x) => stem + x).join('/');

  bool pronominal(String v) {
    final tp = _modelOf(v);
    final suff = tp['suffixe'] as String;
    return suff.length >= 4 && suff.endsWith('se');
  }

  String? baseOf(String v) {
    if (!v.endsWith('rse') || v.length < 5) return null;
    return v.substring(0, v.length - 2);
  }

  Map<String, List<String>> _forms(String v) {
    final tp = _modelOf(v);
    final stem = v.substring(0, v.length - (tp['suffixe'] as String).length);
    final c = (tp['champs'] as List<List<String>>);
    List<String> field([int i = 0]) =>
        c.length > i ? c[i] : const <String>[];
    final ppc = field(10);
    List<String> pp4;
    List<String> finPp4;
    if (_one(stem, ppc.isNotEmpty ? ppc[0] : '').isNotEmpty) {
      pp4 = ppc.map((x) => _one(stem, x)).toList();
      finPp4 = ppc;
    } else {
      final b = baseOf(v);
      var ok = false;
      var out4 = List.filled(4, '');
      var cbb = const [''];
      if (b != null && set.tplOf.containsKey(b)) {
        final tb = _modelOf(b);
        final rb = b.substring(0, b.length - (tb['suffixe'] as String).length);
        final cb = (tb['champs'] as List<List<String>>);
        cbb = cb.length > 10 ? cb[10] : const [''];
        out4 = cbb.map((x) => _one(rb, x)).toList();
        ok = true;
      }
      pp4 = ok ? out4 : List.filled(4, '');
      finPp4 = ok ? cbb : List.filled(4, '');
    }
    return {
      'pri': glueFullForms(stem, field(0), 6),
      'pii': glueFullForms(stem, field(1), 6),
      'ifi': glueFullForms(stem, field(2), 6),
      'fti': glueFullForms(stem, field(3), 6),
      'cni': glueFullForms(stem, field(4), 6),
      'prs': glueFullForms(stem, field(5), 6),
      'pis': glueFullForms(stem, field(6), 6),
      'fts': glueFullForms(stem, field(7), 6),
      'imp': glueFullForms(stem, field(8), 5),
      'ger': [field(9).join(',')],
      'gerBrut': field(9),
      'pp4': pp4,
      'finPp4': finPp4,
      'finPri': field(0),
      'finPii': field(1),
      'finIfi': field(2),
      'finFti': field(3),
      'finCni': field(4),
      'finPrs': field(5),
      'finPis': field(6),
      'finFts': field(7),
      'finImp': field(8),
    };
  }

  Map<String, List<String>> _haberAux() {
    final tp = _modelOf('haber');
    final stem = 'haber'.substring(
        0, 'haber'.length - (tp['suffixe'] as String).length);
    final c = (tp['champs'] as List<List<String>>);
    return {
      'pri': glueFullForms(stem, c[0], 6),
      'pii': glueFullForms(stem, c[1], 6),
      'ifi': glueFullForms(stem, c[2], 6),
      'fti': glueFullForms(stem, c[3], 6),
      'cni': glueFullForms(stem, c[4], 6),
      'prs': glueFullForms(stem, c[5], 6),
      'pis': glueFullForms(stem, c[6], 6),
      'finPri': c[0],
      'finPii': c[1],
      'finIfi': c[2],
      'finFti': c[3],
      'finCni': c[4],
      'finPrs': c[5],
      'finPis': c[6],
    };
  }

  List<String> _rows(List<String> forms6, bool clitic) {
    final out = <String>[];
    for (var i = 0; i < 6; i++) {
      final fx = i < forms6.length ? forms6[i] : '';
      out.add(fx.isEmpty ? '' : (clitic ? '${_CLIT_ES[i]} ' : '') + fx);
    }
    return out;
  }

  List<String> _compound(List<String> aux6, String pp, bool clitic) {
    final out = <String>[];
    for (var i = 0; i < 6; i++) {
      final h = i < aux6.length ? aux6[i] : '';
      final rest = h.isEmpty ? '' : '$h $pp';
      out.add(rest.isEmpty ? '' : (clitic ? '${_CLIT_ES[i]} ' : '') + rest);
    }
    return out;
  }

  List<String> _imperative(List<String> imp, bool clitic) {
    final out = <String>[];
    for (var i = 0; i < 5; i++) {
      final fx = i < imp.length ? imp[i] : '';
      final c = _ORD_IMP_ES[i];
      out.add(fx.isEmpty ? '' : (clitic && c > 0 ? '$fx-${_CLIT_ES[c]}' : fx));
    }
    return out;
  }

  List<Mood> render(String v) {
    final clitic = pronominal(v);
    final f = _forms(v), H = _haberAux();
    final pp = f['pp4']![0];
    final moods = <Mood>[];
    moods.add(Mood('Infinitivo', [
      Tense('presente', ['—'], [v]),
      Tense('compuesto', ['—'], [pp.isEmpty ? '' : '${H['pri']![2]} $pp'],
          [pp.isEmpty ? '' : f['finPp4']![0]]),
    ]));
    moods.add(Mood('Indicativo', [
      Tense('presente', _PERS_ES, _rows(f['pri']!, clitic), f['finPri']),
      Tense('pretérito imperfecto', _PERS_ES, _rows(f['pii']!, clitic), f['finPii']),
      Tense('pretérito perfecto simple', _PERS_ES, _rows(f['ifi']!, clitic), f['finIfi']),
      Tense('futuro simple', _PERS_ES, _rows(f['fti']!, clitic), f['finFti']),
      Tense('pretérito perfecto compuesto', _PERS_ES, _compound(H['pri']!, pp, clitic), H['finPri']),
      Tense('pretérito pluscuamperfecto', _PERS_ES, _compound(H['pii']!, pp, clitic), H['finPii']),
      Tense('pretérito anterior', _PERS_ES, _compound(H['ifi']!, pp, clitic), H['finIfi']),
      Tense('futuro compuesto', _PERS_ES, _compound(H['fti']!, pp, clitic), H['finFti']),
    ]));
    moods.add(Mood('Condicional', [
      Tense('simple', _PERS_ES, _rows(f['cni']!, clitic), f['finCni']),
      Tense('compuesto', _PERS_ES, _compound(H['cni']!, pp, clitic), H['finCni']),
    ]));
    moods.add(Mood('Subjuntivo', [
      Tense('presente', _PERS_SUB_ES, _rows(f['prs']!, clitic), f['finPrs']),
      Tense('pretérito imperfecto', _PERS_SUB_ES, _rows(f['pis']!, clitic), f['finPis']),
      Tense('futuro (arcaico)', _PERS_SUB_ES, _rows(f['fts']!, clitic), f['finFts']),
      Tense('pretérito perfecto', _PERS_SUB_ES, _compound(H['prs']!, pp, clitic), H['finPrs']),
      Tense('pretérito pluscuamperfecto', _PERS_SUB_ES, _compound(H['pis']!, pp, clitic), H['finPis']),
    ]));
    moods.add(Mood('Imperativo', [
      Tense('presente', _IMP_PER_ES, _imperative(f['imp']!, clitic),
          f['finImp']!.take(5).toList()),
    ]));
    moods.add(Mood('Participio', [
      Tense(
          'pasado',
          const [
            'masculino singular',
            'masculino plural',
            'femenino singular',
            'femenino plural'
          ],
          (f['pp4']!),
          f['finPp4']),
      Tense('presente', ['gerundio'], f['ger']!, f['gerBrut']),
    ]));
    return moods;
  }
}

/* Common Iberia: models "name;P;I;R;F;C;S1;S2;IMP;PP[;AUX]", the !
   mark gives the whole form, + glues the participle to the stem. */
class IberianForms {
  final Tpl tp;
  final String stem;
  IberianForms(this.tp, this.stem);

  List<String> full(List<String> pieces) {
    if (pieces.isEmpty) return [];
    return pieces.map((x) {
      if (x.startsWith('!')) return x.substring(1);
      return stem + x;
    }).toList();
  }

  List<List<String>> get c => (tp['champs'] as List<List<String>>);
}

/// The endings of an Iberian field: the piece is the ending; the whole
/// form marked "!" is cut after the stem when the stem appears in it,
/// otherwise the "!" forms without stem are cut by their longest
/// common prefix ( otherwise no highlighting ).
List<String> iberianEnds(String stem, List<String> pieces) {
  final perPiece = <String>[];
  final fullIdx = <int>[];
  for (var i = 0; i < pieces.length; i++) {
    final x = pieces[i];
    if (x.isEmpty) {
      perPiece.add('');
    } else if (x.startsWith('!')) {
      final f = x.substring(1);
      final end = stem.isNotEmpty && f.startsWith(stem) && f.length > stem.length
          ? f.substring(stem.length)
          : '';
      if (end.isEmpty) fullIdx.add(i);
      perPiece.add(end);
    } else {
      perPiece.add(x);
    }
  }
  if (fullIdx.isEmpty) return perPiece;
  final full = [for (final i in fullIdx) pieces[i].substring(1)];
  final lcp = conjCommonPrefixEnds(full);
  for (var k = 0; k < fullIdx.length && k < lcp.length; k++) {
    if (lcp[k].isNotEmpty) perPiece[fullIdx[k]] = lcp[k];
  }
  return perPiece;
}

/* ----------------------------------------------------------------ITALY */

class It {
  final ConjSet set;
  It(this.set);

  IberianForms sheet(String v) {
    final tp = set.tpls[set.tplOf[v]!];
    return IberianForms(tp, set.stemOf[v] ?? '');
  }

  String participle(IberianForms r, String v) {
    final pp = r.c.length > 8 ? r.c[8].join(',') : '';
    if (pp.startsWith('+')) return '${r.stem}${pp.substring(1)}';
    if (pp.isNotEmpty) return pp;
    if (v.endsWith('are')) return '${r.stem}ato';
    if (v.endsWith('ire')) return '${r.stem}ito';
    return '${r.stem}uto';
  }

  static const _ix = {'P': 0, 'I': 1, 'R': 2, 'F': 3, 'C': 4, 'S1': 5, 'S2': 6};

  List<String> _aux(String name, String field) {
    final tp = set.tpls[set.tplOf[name]!];
    final r = IberianForms(tp, set.stemOf[name] ?? '');
    return r.full(r.c[_ix[field]!]);
  }

  List<Mood> render(String v) {
    final r = sheet(v);
    final pp = participle(r, v);
    final auxFields = r.c.length > 9 ? r.c[9] : const ['a'];
    final auxName =
        auxFields.isNotEmpty && auxFields[0].contains('e') ? 'essere' : 'avere';
    List<String> aux(String field) => _aux(auxName, field);
    List<String> auxEnd(String field) {
      final tp = set.tpls[set.tplOf[auxName]!];
      return iberianEnds(set.stemOf[auxName] ?? '',
          (tp['champs'] as List<List<String>>)[_ix[field]!]);
    }

    List<String> compound(List<String> a) =>
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
    Tense simple(String name, List<String> pieces) =>
        Tense(name, per1, r.full(pieces), iberianEnds(r.stem, pieces));
    Tense simpleSub(String name, List<String> pieces) =>
        Tense(name, per2, r.full(pieces), iberianEnds(r.stem, pieces));

    final moods = <Mood>[];
    final finPp = r.stem.isNotEmpty && pp.startsWith(r.stem) && pp.length > r.stem.length
        ? pp.substring(r.stem.length)
        : conjDerivedEnd(pp, v);
    moods.add(Mood('Infinito', [
      Tense('presente', ['—'], [v]),
      Tense('passato', ['—'], ['${aux('P')[0]} $pp'], [finPp]),
    ]));
    moods.add(Mood('Indicativo', [
      simple('presente', r.c[0]),
      simple('imperfetto', r.c[1]),
      simple('passato remoto', r.c[2]),
      simple('futuro semplice', r.c[3]),
      Tense('passato prossimo', per1, compound(aux('P')), auxEnd('P')),
      Tense('trapassato', per1, compound(aux('I')), auxEnd('I')),
      Tense('futuro anteriore', per1, compound(aux('F')), auxEnd('F')),
    ]));
    moods.add(Mood('Condizionale', [
      simple('presente', r.c[4]),
      Tense('passato', per1, compound(aux('C')), auxEnd('C')),
    ]));
    moods.add(Mood('Congiuntivo', [
      simpleSub('presente', r.c[5]),
      simpleSub('imperfetto', r.c[6]),
      Tense('passato', per2, compound(aux('S1')), auxEnd('S1')),
      Tense('trapassato', per2, compound(aux('S2')), auxEnd('S2')),
    ]));
    moods.add(Mood('Imperativo', [
      Tense('presente', impPer, r.full(r.c[7]), iberianEnds(r.stem, r.c[7])),
    ]));
    moods.add(Mood('Participio', [
      Tense('passato', ['participio passato'], [pp], [finPp]),
    ]));
    return moods;
  }
}

/* -------------------------------------------------------------PORTUGAL */

class Pt {
  final ConjSet set;
  Pt(this.set);

  IberianForms sheet(String v) {
    final tp = set.tpls[set.tplOf[v]!];
    return IberianForms(tp, set.stemOf[v] ?? '');
  }

  static const _ix = {'P': 0, 'I': 1, 'R': 2, 'F': 3, 'C': 4, 'S1': 5, 'S2': 6};

  List<String> _auxTer(String field) {
    final tp = set.tpls[set.tplOf['ter']!];
    final r = IberianForms(tp, set.stemOf['ter'] ?? '');
    return r.full(r.c[_ix[field]!]);
  }

  String participle(IberianForms r) {
    final pp = r.c.length > 8 ? r.c[8].join(',') : '';
    if (pp.startsWith('!')) return pp.substring(1);
    return '${r.stem}$pp';
  }

  List<Mood> render(String v) {
    final r = sheet(v);
    final pp = participle(r);
    List<String> aux(String field) => _auxTer(field);
    List<String> auxEnd(String field) {
      final tp = set.tpls[set.tplOf['ter']!];
      return iberianEnds(set.stemOf['ter'] ?? '',
          (tp['champs'] as List<List<String>>)[_ix[field]!]);
    }

    List<String> compound(List<String> a) =>
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
    Tense simple(String name, List<String> pieces) =>
        Tense(name, per1, r.full(pieces), iberianEnds(r.stem, pieces));
    Tense simpleSub(String name, List<String> pieces) =>
        Tense(name, per2, r.full(pieces), iberianEnds(r.stem, pieces));

    final moods = <Mood>[];
    final finPp = r.stem.isNotEmpty && pp.startsWith(r.stem) && pp.length > r.stem.length
        ? pp.substring(r.stem.length)
        : conjDerivedEnd(pp, v);
    moods.add(Mood('Infinitivo', [
      Tense('impessoal', ['—'], [v]),
      Tense('composto', ['—'], ['${aux('P')[0]} $pp'], [finPp]),
    ]));
    moods.add(Mood('Indicativo', [
      simple('presente', r.c[0]),
      simple('pretérito imperfeito', r.c[1]),
      simple('pretérito perfeito simples', r.c[2]),
      simple('futuro simples', r.c[3]),
      Tense('pretérito mais-que-perfeito', per1, compound(aux('I')), auxEnd('I')),
      Tense('pretérito perfeito composto', per1, compound(aux('P')), auxEnd('P')),
      Tense('futuro anterior', per1, compound(aux('F')), auxEnd('F')),
    ]));
    moods.add(Mood('Condicional', [
      simple('presente', r.c[4]),
      Tense('passado', per1, compound(aux('C')), auxEnd('C')),
    ]));
    moods.add(Mood('Conjuntivo', [
      simpleSub('presente', r.c[5]),
      simpleSub('pretérito imperfeito', r.c[6]),
      Tense('pretérito perfeito composto', per2, compound(aux('S1')), auxEnd('S1')),
      Tense('pretérito mais-que-perfeito composto', per2, compound(aux('S2')), auxEnd('S2')),
    ]));
    moods.add(Mood('Imperativo', [
      Tense('presente', impPer, r.full(r.c[7]), iberianEnds(r.stem, r.c[7])),
    ]));
    moods.add(Mood('Particípio', [
      Tense('passado', ['particípio passado'], [pp], [finPp]),
    ]));
    return moods;
  }
}

/* --------------------------------------------------------------GERMANY */

const _PERS_DE = ['ich', 'du', 'er·sie·es', 'wir', 'ihr', 'sie·Sie'];
const _IMP_PER_DE = ['(du)', '(ihr)', 'Sie'];

class De {
  final ConjSet set;
  De(this.set);

  /// Full forms: the separable particle glues at the end.
  List<String> full(String stem, List<String> pieces, String sep) {
    if (pieces.isEmpty) return [];
    return pieces
        .map((x) => stem + x + (x.isNotEmpty && sep.isNotEmpty ? ' $sep' : ''))
        .toList();
  }

  List<String> _aux(String name, int ix) {
    final tp = set.tpls[set.tplOf[name]!];
    final c = (tp['champs'] as List<List<String>>);
    return full(set.stemOf[name] ?? '', c[ix], '');
  }

  /// The endings of an auxiliary field: the German model carries pure
  /// ending pieces, glued to the encoded stem.
  List<String> _auxEnd(String name, int ix) {
    final tp = set.tpls[set.tplOf[name]!];
    final c = (tp['champs'] as List<List<String>>);
    return c.length > ix ? c[ix] : const <String>[];
  }

  List<Mood> render(String v) {
    final tp = set.tpls[set.tplOf[v]!];
    final c = (tp['champs'] as List<List<String>>);
    final stem = set.stemOf[v] ?? '';
    // sheet encoded "verb:stem:pp:aux[:sep]"
    final p = set.parts[v] ?? <String>[v];
    final sheet = _DeSheet._(
        p.length > 2 ? p[2] : '', p.length > 3 ? p[3] : 'h',
        p.length > 4 ? p[4] : '');
    final P = full(stem, c[0], sheet.sep);
    final R = full(stem, c[1], sheet.sep);
    final IMP = full(stem, c.length > 2 ? c[2] : const [], sheet.sep);
    final k2 = c.length > 3 ? c[3].join(',') : 'w';
    final W = k2 == 'w'
        ? _aux('werden', 0).map((x) => '$x $v').toList()
        : full(stem, k2.split(','), '');
    final auxName = sheet.aux == 's' ? 'sein' : 'haben';
    final auxK2 = sheet.aux == 's'
        ? const ['wäre', 'wärest', 'wäre', 'wären', 'wärt', 'wären']
        : const ['hätte', 'hättest', 'hätte', 'hätten', 'hättet', 'hätten'];
    List<String> compound(List<String> a, String chunk) =>
        a.map((h) => h.isEmpty ? '' : '$h $chunk').toList();

    final moods = <Mood>[];
    moods.add(Mood('Infinitiv', [
      Tense('Präsens', ['—'], [v]),
      Tense(
          'Perfekt', ['—'], ['${sheet.pp} ${sheet.aux == 's' ? 'sein' : 'haben'}'],
          /* the ending of the participle: the final t, the auxiliary
             haben/sein never ends with t and never steals it */
          [sheet.pp.endsWith('t') ? 't' : '']),
    ]));
    moods.add(Mood('Indikativ', [
      Tense('Präsens', _PERS_DE, P, c[0]),
      Tense('Präteritum', _PERS_DE, R, c.length > 1 ? c[1] : const []),
      Tense('Perfekt', _PERS_DE, compound(_aux(auxName, 0), sheet.pp), _auxEnd(auxName, 0)),
      Tense('Plusquamperfekt', _PERS_DE, compound(_aux(auxName, 1), sheet.pp), _auxEnd(auxName, 1)),
      Tense('Futur I', _PERS_DE, compound(_aux('werden', 0), v), _auxEnd('werden', 0)),
      Tense(
          'Futur II',
          _PERS_DE,
          compound(_aux('werden', 0),
              '${sheet.pp} ${sheet.aux == 's' ? 'sein' : 'haben'}'),
          _auxEnd('werden', 0)),
    ]));
    moods.add(Mood('Konjunktiv II', [
      Tense('Präsens', _PERS_DE, W,
          k2 == 'w' ? _auxEnd('werden', 0) : k2.split(',')),
      Tense('Vergangenheit', _PERS_DE, compound(auxK2, sheet.pp),
          sheet.aux == 's'
              ? const ['e', 'est', 'e', 'en', 't', 'en']
              : const ['e', 'est', 'e', 'en', 'et', 'en']),
    ]));
    moods.add(Mood('Imperativ', [
      Tense('Präsens', _IMP_PER_DE, IMP, c.length > 2 ? c[2] : const []),
    ]));
    moods.add(Mood('Partizip', [
      Tense('Partizip II', ['Partizip II'], [sheet.pp],
          [sheet.pp.endsWith('en')
              ? 'en'
              : sheet.pp.endsWith('t')
                  ? 't'
                  : '']),
    ]));
    return moods;
  }
}

class _DeSheet {
  final String pp;
  final String aux;
  final String sep;
  _DeSheet._(this.pp, this.aux, this.sep);
}

/* ------------------------------------------------ facade per language - */
class ConjugTables {
  final String language;
  final ConjSet set;
  final Set<String> fromWiktionary; // verbs whose source is the Wiktionary
  final Fr fr;
  final En en;
  final Es es;
  final It it;
  final Pt pt;
  final De de;
  final Pl? pl;
  final Cs? cs;
  final Ro? ro;

  ConjugTables(this.language, this.set, this.fromWiktionary,
      [Map<String, SlTok>? toks])
      : fr = Fr(set),
        en = En(set),
        es = Es(set),
        it = It(set),
        pt = Pt(set),
        de = De(set),
        pl = language == 'pl' ? Pl(set, toks ?? {}) : null,
        cs = language == 'cs' ? Cs(set, toks ?? {}) : null,
        ro = language == 'ro' ? Ro(set, toks ?? {}) : null;

  static const _stemmed = {'de': true, 'it': true, 'pt': true};

  factory ConjugTables.from(String language, String tplStr,
      String verbsStr, String defsStr, String vsrcStr) {
    if (language == 'pl' || language == 'cs' || language == 'ro') {
      final names = <String>[], toks = <String, SlTok>{};
      for (final grp in verbsStr.split('\n')) {
        for (final tok in grp.split(',')) {
          if (tok.isEmpty) continue;
          final c = tok.split(':');
          names.add(c[0]);
          toks[c[0]] = SlTok(c);
        }
      }
      final defs = <String, String>{};
      for (final part in defsStr.split('\u0002')) {
        if (part.isEmpty) continue;
        final k = part.split('\u0001');
        if (k.length == 2 && k[0].isNotEmpty) defs[k[0]] = k[1];
      }
      final tplOf = <String, int>{}, folds = <String>[];
      for (var i = 0; i < names.length; i++) {
        tplOf[names[i]] = i;
        folds.add(conjNormalize(names[i]));
      }
      final set = ConjSet(const [], names, tplOf, const {}, const {},
          folds, defs);
      final fromWikit = <String>{};
      for (final l in vsrcStr.split('\n')) {
        if (l.isNotEmpty) fromWikit.add(l);
      }
      return ConjugTables(language, set, fromWikit, toks);
    }
    final set = ConjSet.from(tplStr, verbsStr, defsStr,
        stems: _stemmed[language] ?? false);
    final fromWikit = <String>{};
    for (final l in vsrcStr.split('\n')) {
      if (l.isNotEmpty) fromWikit.add(l);
    }
    return ConjugTables(language, set, fromWikit);
  }

  /// The source of the conjugation of a verb: 'w' Wiktionary (CC BY-SA
  /// 4.0), 'g' home-made generator of the project (MIT, public domain
  /// data).
  String verbSource(String v) => fromWiktionary.contains(v) ? 'w' : 'g';

  bool knows(String v) => set.tplOf.containsKey(v);

  /// The displayed title of the verb.
  String title(String v, {bool clitic = false}) =>
      language == 'fr' && clitic ? pronominalize(v) : v;

  Map<String, String> header(String v, {bool clitic = false}) {
    final out = <String, String>{'titre': title(v, clitic: clitic)};
    if (language == 'fr') out.addAll(fr.header(v, clitic));
    return out;
  }

  List<Meaning> definition(String v) {
    final d = set.defs[v];
    return d == null ? const [] : conjMeanings(d);
  }

  List<Mood> render(String v, {bool clitic = false}) {
    switch (language) {
      case 'fr':
        return fr.render(v, clitic);
      case 'en':
        return const [];
      case 'es':
        return es.render(v);
      case 'de':
        return de.render(v);
      case 'it':
        return it.render(v);
      case 'pt':
        return pt.render(v);
      case 'pl':
        return pl?.render(v) ?? const [];
      case 'cs':
        return cs?.render(v) ?? const [];
      case 'ro':
        return ro?.render(v) ?? const [];
    }
    return const [];
  }

  /// Double -ed form (US) / -t (GB): "burned (US) · burnt (GB)".
  static String englishMark(String f) {
    if (!f.contains('/')) return f;
    final p = f.split('/');
    if (p.length != 2) return f;
    final a = p[0], b = p[1];
    final us = a.endsWith('ed') && b.endsWith('t') ? a : (b.endsWith('ed') && a.endsWith('t') ? b : null);
    if (us == null) return f;
    final gb = us == a ? b : a;
    return '$us (US) · $gb (GB)';
  }

  /// The English grid: infinitive, preterite, participle, seven
  /// neighbours.
  List<Map<String, String>> englishGrid(String v) {
    final out = <Map<String, String>>[];
    for (final w in en.neighbours(v)) {
      final f = en.forms(w);
      out.add({
        'verbe': w,
        'preterit': englishMark(en.preteriteOf(f['past'] as List<String>)),
        'pp': englishMark(f['pp'] as String)
      });
    }
    return out;
  }

  bool infinitiveOnly(String v) => language == 'fr' && fr.infinitiveOnly(v);
}


/* The Romanian engine: verbs copied verbatim from the Romanian
   Wiktionary via all the wiktionaries (kaikki.org, CC BY-SA 4.0);
   compound tenses and future computed on the device from regular
   auxiliaries.
   RO token: name:present(6):imperfect(6):perfect(6):pluperfect(6):
   subjunctive(6):imperative(2):participle:gerund, ';' fields.
   SPDX-License-Identifier: MIT. */

const _PERS_RO = ['eu', 'tu', 'el·ea', 'noi', 'voi', 'ei·ele'];
const _PERS_IMP_RO = ['(tu)', '(voi)'];
const _VIITOR_RO = ['voi', 'vei', 'va', 'vom', 'veți', 'vor'];
const _COND_RO = ['aș', 'ai', 'ar', 'am', 'ați', 'ar'];
const _PC_RO = ['am', 'ai', 'a', 'am', 'ați', 'au'];

class Ro {
  final ConjSet set;
  final Map<String, SlTok> toks;
  Ro(this.set, this.toks);

  List<String> _g(SlTok t, int i) => t.c[i].split(';');

  /// The endings of the regular auxiliaries: the final vowel of the
  /// auxiliary stays out of the highlighting, the person consonant
  /// alone.
  static const _finPC = ['m', 'i', '', 'm', 'ți', 'u'];
  static const _finViitor = ['i', 'i', '', 'm', 'ți', 'r'];
  static const _finCond = ['ș', 'i', 'r', 'm', 'ți', 'r'];

  List<Mood> render(String v) {
    final t = toks[v];
    if (t == null) return const [];
    final P = _g(t, 1), I = _g(t, 2), R = _g(t, 3), PQ = _g(t, 4);
    final S = _g(t, 5), IMP = _g(t, 6);
    final pp = t.c[7], ger = t.c[8];
    List<String> compound(List<String> aux) =>
        aux.map((a) => '$a $pp').toList();
    List<String> infinite(List<String> aux) =>
        aux.map((a) => '$a $v').toList();
    final moods = <Mood>[];
    moods.add(Mood('Infinitiv', [
      Tense('prezent', ['—'], ['a $v']),
      Tense('perfect', ['—'], ['a fi $pp'], [conjDerivedEnd(pp, v)]),
    ]));
    moods.add(Mood('Indicativ', [
      Tense('prezent', _PERS_RO, P, conjCommonPrefixEnds(P)),
      Tense('imperfect', _PERS_RO, I, conjCommonPrefixEnds(I)),
      Tense('perfect simplu', _PERS_RO, R, conjCommonPrefixEnds(R)),
      Tense('mai mult ca perfect', _PERS_RO, PQ, conjCommonPrefixEnds(PQ)),
      Tense('perfect compus', _PERS_RO, compound(_PC_RO), _finPC),
      Tense('viitor simplu', _PERS_RO, infinite(_VIITOR_RO), _finViitor),
    ]));
    moods.add(Mood('Condițional prezent', [
      Tense('—', _PERS_RO, infinite(_COND_RO), _finCond),
    ]));
    moods.add(Mood('Conjunctiv', [
      Tense('prezent', _PERS_RO, S, conjCommonPrefixEnds(S)),
    ]));
    moods.add(Mood('Imperativ', [
      Tense('prezent', _PERS_IMP_RO, IMP, conjCommonPrefixEnds(IMP, max: 3)),
    ]));
    moods.add(Mood('Participiu', [
      Tense('trecut', ['—'], [pp], [conjDerivedEnd(pp, v)]),
    ]));
    moods.add(Mood('Gerunziu', [
      Tense('prezent', ['—'], [ger], [conjDerivedEnd(ger, v)]),
    ]));
    return moods;
  }
}

/* ------------------------------------------------------------------pl, cs */

/* Polish, Romanian and Czech: dedicated engines, data verified from
   the Wiktionary (kaikki.org, CC BY-SA 4.0); phrases computed on the
   device.
   Romanian: all the forms of the Romanian Wiktionary, copied
   verbatim; future, conditional and compound perfect assembled with
   the regular auxiliaries (a vrea, a avea).
   Token: name:s1[:s3]:p3:W:V:imp2:aspect; additional forms computed.
   SPDX-License-Identifier: MIT. */
class SlTok {
  final List<String> c;
  SlTok(this.c);
  String get name => c[0];
}
class Pl {
  final ConjSet set;
  final Map<String, SlTok> toks;
  Pl(this.set, this.toks);

  static const _per = ['ja', 'ty', 'on·ona', 'my', 'wy', 'oni'];
  static const _perP = [
    'ja m.', 'ja f.', 'ty m.', 'ty f.', 'on', 'ona', 'ono',
    'my m.', 'my n.', 'wy m.', 'wy n.', 'oni', 'one'
  ];
  static const _perImp = ['ty', 'my', 'wy'];

  static String _spell(String w) {
    return w
        .replaceAll('ge', 'że')
        .replaceAll('ke', 'cze')
        .replaceAll('de', 'dzie')
        .replaceAll('te', 'cie');
  }

  static List<String> _present(SlTok t) => _present2(t)[0];

  /// The present forms and their endings: the suffixes laid on the
  /// stem are known, the first person and the third of the plural
  /// ( verbatim data ) are cut after the stem when it appears in them.
  static List<List<String>> _present2(SlTok t) {
    final s1 = t.c[1], p3 = t.c[2];
    final stem = s1.endsWith('ę') || s1.endsWith('m') ? s1.substring(0, s1.length - 1) : s1;
    final voy = stem.isNotEmpty && 'aeiyouą'.contains(stem[stem.length - 1]);
    String s2, s3, p1, p2;
    List<String> ends;
    final end1 = stem.isNotEmpty && s1.startsWith(stem) && s1.length > stem.length
        ? s1.substring(stem.length)
        : '';
    final endP3 = stem.isNotEmpty && p3.startsWith(stem) && p3.length > stem.length
        ? p3.substring(stem.length)
        : '';
    if (voy) {
      s2 = stem + 'sz';
      s3 = stem;
      p1 = stem + 'my';
      p2 = stem + 'cie';
      ends = [end1, 'sz', '', 'my', 'cie', endP3];
    } else {
      final der = stem[stem.length - 1];
      final eseries = der == 'd' || der == 't' || der == 'k' || der == 'g' ||
          der == 'j' || der == 'ł' ||
          (stem.length > 1 &&
              const ['sz', 'ż', 'cz', 'rz']
                  .contains(stem.substring(stem.length - 2)));
      if (eseries) {
        s2 = _spell(stem + 'esz');
        s3 = _spell(stem + 'e');
        p1 = _spell(stem + 'emy');
        p2 = _spell(stem + 'ecie');
        ends = [end1, 'esz', 'e', 'emy', 'ecie', endP3];
      } else {
        s2 = stem + 'isz';
        s3 = stem + 'i';
        p1 = stem + 'imy';
        p2 = stem + 'icie';
        ends = [end1, 'isz', 'i', 'imy', 'icie', endP3];
      }
    }
    return [
      [s1, s2, s3, p1, p2, p3],
      ends
    ];
  }

  /// Endings of the Polish "bede" auxiliary of the future, the past
  /// and the conditional.
  static const _finBede = ['ę', 'sz', 'e', 'my', 'cie', 'ą'];
  static const _finPasse = [
    'łem', 'łam', 'łeś', 'łaś', 'ł', 'a', 'o',
    'śmy', 'śmy', 'ście', 'ście', 'i', 'y'
  ];
  static const _finCond = [
    'bym', 'bym', 'byś', 'byś', 'by', 'by', 'by',
    'byśmy', 'byśmy', 'byście', 'byście', 'by', 'by'
  ];

  static List<String> _past(SlTok t) {
    final w = t.c[3], v = t.c[4];
    final base = w.substring(0, w.length - 1); // without the final ł
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

  // Suffixes and indices of the conditional (past participle + bym, byś...).
  static const _condSuf = [
    'bym', 'bym', 'byś', 'byś', 'by', 'by', 'by', 'byśmy', 'byśmy',
    'byście', 'byście', 'by', 'by'
  ];
  static const _condIdx = [4, 5, 4, 5, 4, 5, 6, 11, 12, 11, 12, 11, 12];

  /// Exceptional verb (t.c[1]=='E'): verbatim forms of the Wiktionary.
  static List<Mood> _renderEx(SlTok t) {
    final pres = t.c[2].split(';');
    final past = t.c[3].split(';');
    final imp = t.c[4].split(';');
    final asp = t.c[5];
    final mood = <Mood>[];
    final ind = <Tense>[];
    if (asp == 'i') {
      ind.add(Tense('czas teraźniejszy', _per, pres, conjCommonPrefixEnds(pres)));
      ind.add(Tense('czas przyszły', _per,
          ['będę', 'będziesz', 'będzie', 'będziemy', 'będziecie', 'będą']
              .map((b) => '$b ${t.name}').toList(), _finBede));
    } else {
      ind.add(Tense('czas przyszły', _per, pres, conjCommonPrefixEnds(pres)));
    }
    ind.add(Tense('czas przeszły', _perP, past));
    mood.add(Mood('Tryb oznajmujący', ind));
    final cond = [
      for (var i = 0; i < 13; i++) '${past[_condIdx[i]]}${_condSuf[i]}'
    ];
    mood.add(Mood('Tryb przypuszczający',
        [Tense('czas przeszły', _perP, cond, _finCond)]));
    if (imp.any((x) => x.isNotEmpty)) {
      mood.add(Mood('Tryb rozkazujący', [Tense('czas teraźniejszy', _perImp, imp)]));
    }
    return mood;
  }

  List<Mood> render(String v) {
    if (v == 'być') return _byc;
    final t = toks[v];
    if (t == null || v == 'iść') return v == 'iść' ? _isc : const [];
    if (t.c.length > 1 && t.c[1] == 'E') return _renderEx(t);
    final asp = t.c[6];
    final mood = <Mood>[];
    final pres2 = _present2(t);
    final pres = pres2[0];
    final ends = pres2[1];
    final ind = <Tense>[];
    if (asp == 'i') {
      ind.add(Tense('czas teraźniejszy', _per, pres, ends));
      ind.add(Tense('czas przyszły', _per,
          ['będę', 'będziesz', 'będzie', 'będziemy', 'będziecie', 'będą']
              .map((b) => '$b $v').toList(), _finBede));
    } else {
      ind.add(Tense('czas przyszły', _per, pres, ends));
    }
    ind.add(Tense('czas przeszły', _perP, _past(t), _finPasse));
    mood.add(Mood('Tryb oznajmujący', ind));
    mood.add(Mood('Tryb przypuszczający',
        [Tense('czas przeszły', _perP, _cond(t), _finCond)]));
    final imp2 = t.c[5];
    mood.add(Mood('Tryb rozkazujący', [
      Tense('czas teraźniejszy', _perImp,
          [imp2, imp2 + 'my', imp2 + 'cie'], const ['', 'my', 'cie'])
    ]));
    return mood;
  }

  static List<Mood> get _byc {
    return [
      Mood('Tryb oznajmujący', [
        Tense('czas teraźniejszy', _per,
            const ['jestem', 'jesteś', 'jest', 'jesteśmy', 'jesteście', 'są'],
            const ['', 'ś', '', 'śmy', 'ście', '']),
        Tense('czas przyszły', _per,
            const ['będę', 'będziesz', 'będzie', 'będziemy', 'będziecie', 'będą'],
            _finBede),
        Tense('czas przeszły', _perP, const [
          'byłem', 'byłam', 'byłeś', 'byłaś', 'był', 'była', 'było',
          'byliśmy', 'byłyśmy', 'byliście', 'byłyście', 'byli', 'były'
        ], _finPasse),
      ]),
      Mood('Tryb przypuszczający', [Tense('czas przeszły', _perP, const [
        'byłbym', 'byłabym', 'byłbyś', 'byłabyś', 'byłby', 'byłaby', 'byłoby',
        'bylibyśmy', 'byłybyśmy', 'bylibyście', 'byłybyście', 'byliby', 'byłyby'
      ], _finCond)]),
      Mood('Tryb rozkazujący', [Tense(
          'présent', _perImp, const ['bądź', 'bądźmy', 'bądźcie'])]),
    ];
  }

  static List<Mood> get _isc {
    return [
      Mood('Tryb oznajmujący', [
        Tense('czas teraźniejszy', _per,
            const ['idę', 'idziesz', 'idzie', 'idziemy', 'idziecie', 'idą'],
            const ['ę', 'esz', 'ie', 'my', 'cie', 'ą']),
        Tense('czas przyszły', _per, const [
          'będę iść', 'będziesz iść', 'będzie iść',
          'będziemy iść', 'będziecie iść', 'będą iść'
        ], _finBede),
        Tense('czas przeszły', _perP, const [
          'szedłem', 'szłam', 'szedłeś', 'szłaś', 'szedł', 'szła', 'szło',
          'szliśmy', 'szłyśmy', 'szliście', 'szłyście', 'szli', 'szły'
        ], _finPasse),
      ]),
      Mood('Tryb przypuszczający', [Tense('czas przeszły', _perP, const [
        'szedłbym', 'szłabym', 'szedłbyś', 'szłabyś', 'szedłby', 'szłaby', 'szłoby',
        'szlibyśmy', 'szłybyśmy', 'szlibyście', 'szłybyście', 'szliby', 'szłyby'
      ], _finCond)]),
      Mood('Tryb rozkazujący', [Tense(
          'présent', _perImp, const ['idź', 'idźmy', 'idźcie'])]),
    ];
  }
}

class Cs {
  final ConjSet set;
  final Map<String, SlTok> toks;
  Cs(this.set, this.toks);

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

  /// Czech present endings: by longest common prefix of the six forms,
  /// the first person then also carries its ending when it shares the
  /// stem ( the too irregular forms stay plain ).
  /// Endings of the "budu" auxiliary of the future.
  static const _finBudu = ['u', 'š', 'e', 'me', 'te', 'ou'];
  /// Endings of the past and the conditional: the long form never ends
  /// with these suffixes, the l participle carries them.
  static const _finPasse = [
    'l', 'la', 'l', 'la', 'l', 'la', 'lo',
    'i', 'y', 'i', 'y', 'i', 'y'
  ];

  static List<String> _past(SlTok t) {
    final w = t.c[4], v = t.c[5];
    final base = w.substring(0, w.length - 1); // without the final l
    final nv = v.substring(0, v.length - 1) + 'y';
    return [
      '$w jsem', '$base la jsem', '$w jsi', '$base la jsi',
      w, '$base la', '$base lo',
      '$v jsme', '$nv jsme', '$v jste', '$nv jste', v, nv
    ];
  }

  /// Exceptional verb (t.c[1]=='E'): indicative verbatim from the
  /// Wiktionary, past and conditional built from W and V, imperative
  /// verbatim ( sometimes missing: muset has no imperative ).
  static List<Mood> _renderEx(SlTok t) {
    final pres = t.c[2].split(';');
    final w = t.c[3], v = t.c[4];
    final imp = t.c[5].split(';');
    final asp = t.c[6];
    final synth = SlTok(['', '', '', '', w, v, '', '']);
    final mood = <Mood>[];
    final ind = <Tense>[];
    if (asp == 'i') {
      ind.add(Tense('přítomný', _per, pres, conjCommonPrefixEnds(pres)));
      ind.add(Tense('budoucí', _per,
          ['budu', 'budeš', 'bude', 'budeme', 'budete', 'budou']
              .map((b) => '$b ${t.name}').toList(), _finBudu));
    } else {
      ind.add(Tense('budoucí', _per, pres, conjCommonPrefixEnds(pres)));
    }
    ind.add(Tense('minulý', _perP, _past(synth), _finPasse));
    mood.add(Mood('Oznamovací způsob', ind));
    mood.add(Mood('Podmiňovací způsob',
        [Tense('přítomný', _perP, _cond(synth), _finPasse)]));
    if (imp.any((x) => x.isNotEmpty)) {
      mood.add(Mood('Rozkazovací způsob', [Tense('přítomný', _perImp, imp)]));
    }
    return mood;
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

  List<Mood> render(String v) {
    if (v == 'být') return _byt;
    final t = toks[v];
    if (t == null) return const [];
    if (t.c.length > 1 && t.c[1] == 'E') return _renderEx(t);
    final asp = t.c[7];
    final mood = <Mood>[];
    final pres = _present(t);
    final ind = <Tense>[];
    if (asp == 'i') {
      ind.add(Tense('přítomný', _per, pres, conjCommonPrefixEnds(pres)));
      ind.add(Tense('budoucí', _per,
          ['budu', 'budeš', 'bude', 'budeme', 'budete', 'budou']
              .map((b) => '$b $v').toList(), _finBudu));
    } else {
      ind.add(Tense('budoucí', _per, pres, conjCommonPrefixEnds(pres)));
    }
    ind.add(Tense('minulý', _perP, _past(t), _finPasse));
    mood.add(Mood('Oznamovací způsob', ind));
    mood.add(Mood('Podmiňovací způsob',
        [Tense('přítomný', _perP, _cond(t), _finPasse)]));
    final imp2 = t.c[6];
    String i1, i2;
    if (imp2.endsWith('i')) {
      i1 = imp2.substring(0, imp2.length - 1) + 'ěme';
      i2 = imp2.substring(0, imp2.length - 1) + 'ěte';
    } else {
      i1 = imp2 + 'me';
      i2 = imp2 + 'te';
    }
    mood.add(Mood('Rozkazovací způsob',
        [Tense('přítomný', _perImp, [imp2, i1, i2],
            const ['', 'me', 'te'])]));
    return mood;
  }

  static List<Mood> get _byt {
    return [
      Mood('Oznamovací způsob', [
        Tense('přítomný', _per,
            const ['jsem', 'jsi', 'je', 'jsme', 'jste', 'jsou']),
        Tense('budoucí', _per,
            const ['budu', 'budeš', 'bude', 'budeme', 'budete', 'budou'],
            _finBudu),
        Tense('minulý', _perP, const [
          'byl jsem', 'byla jsem', 'byl jsi', 'byla jsi',
          'byl', 'byla', 'bylo',
          'byli jsme', 'byly jsme', 'byli jste', 'byly jste', 'byli', 'byly'
        ], _finPasse),
      ]),
      Mood('Podmiňovací způsob', [Tense('přítomný', _perP, const [
        'byl bych', 'byla bych', 'byl bys', 'byla bys',
        'byl by', 'byla by', 'bylo by',
        'byli bychom', 'byly bychom', 'byli byste', 'byly byste', 'byli by', 'byly by'
      ], _finPasse)]),
      Mood('Rozkazovací způsob', [Tense(
          'présent', _perImp, const ['buď', 'buďme', 'buďte'])]),
    ];
  }
}