/* The core of the conjugation cards: tenses, tints, highlighting of the
   endings, definitions with multiple meanings. Faithful port of
   web/js/conjugaison/socle.js. SPDX-License-Identifier: MIT. */
import 'package:flutter/material.dart';

/* The common template of the cards, a single constant for the nine
   languages: the ending is burgundy in the light theme and deep pink
   in the dark theme ( burgundy would be unreadable on a dark
   background ), the parentheses switch to a discreet grey. */
const conjEndLight = Color(0xff7d1f2e);
const conjEndDark = Color(0xfff2848f);

Color conjEndingColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.light
        ? conjEndLight
        : conjEndDark;

TextStyle conjEndingStyle(BuildContext context) => TextStyle(
    color: conjEndingColor(context), fontWeight: FontWeight.w700);

TextStyle conjParenStyle(BuildContext context) =>
    TextStyle(color: Theme.of(context).hintColor);

/* The pieces of a text: the segments between parentheses ( and the
   parentheses themselves ) switch to grey, the rest keeps the base
   style. */
List<TextSpan> conjGreySpans(String text, TextStyle? grey) {
  final out = <TextSpan>[];
  var rest = text;
  final re = RegExp(r'\([^)]*\)');
  while (rest.isNotEmpty) {
    final m = re.firstMatch(rest);
    if (m == null) {
      out.add(TextSpan(text: rest));
      break;
    }
    if (m.start > 0) out.add(TextSpan(text: rest.substring(0, m.start)));
    out.add(TextSpan(text: m[0], style: grey));
    rest = rest.substring(m.end);
  }
  return out;
}

/// Case and accents folded for search.
String conjNormalize(String s) {
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

/// The tint class of a tense, from its name.
/// anterieur 6 ( futur anterieur 7 ), compose 4, plus 5, futur 3,
/// simple 2, imparfait 1, present 0, passe or parfait 8, else 9.
int conjTenseTint(String name) {
  final n = conjNormalize(name);
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

/// A tense: name, person labels, forms, raw endings.
class Tense {
  final String name;
  final List<String> pers;
  final List<String> val;
  final List<String>? end;
  Tense(this.name, this.pers, this.val, [this.end]);
}

/// A mood: its name and its tenses.
class Mood {
  final String name;
  final List<Tense> tenses;
  Mood(this.name, this.tenses);
}

/// A highlighted token: the ending in bold, the rest in plain.
class Highlight {
  final String plain; // unhighlighted part, may be empty
  final String? end; // highlighted ending, null = nothing
  Highlight(this.plain, this.end);
}

Highlight conjSplitEnd(String tok, String end) {
  if (end.isEmpty || tok.length < end.length || !tok.endsWith(end)) {
    return Highlight(tok, null);
  }
  return Highlight(tok.substring(0, tok.length - end.length), end);
}

/// A whole token: variants joined by a slash handled pairwise, the
/// clitic of the imperative after the dash stays plain. The slash of
/// the variants stays displayed between them.
List<Highlight> conjTokenPieces(String tok, String end) {
  if (tok.contains('/') &&
      end.contains('/') &&
      tok.split('/').length == end.split('/').length) {
    final tv = tok.split('/'), fv = end.split('/');
    final out = <Highlight>[];
    for (var m = 0; m < tv.length; m++) {
      final p2 = conjSplitEnd(tv[m], fv[m]);
      if (p2.end == null) return [Highlight(tok, null)];
      out.add(m == 0 ? p2 : Highlight('/' + p2.plain, p2.end));
    }
    return out;
  }
  if (tok.contains('-') && !tok.contains('/')) {
    final st = tok.split('-');
    final b2 = conjSplitEnd(st[0], end);
    if (b2.end != null) {
      final out = <Highlight>[b2];
      for (var m = 1; m < st.length; m++) {
        out.add(Highlight('-${st[m]}', null));
      }
      return out;
    }
    return [Highlight(tok, null)];
  }
  return [conjSplitEnd(tok, end)];
}

/// The highlighted pieces of a form: the sought ending from right to
/// left in the tokens, the one of the auxiliary wins the compounds.
/// The space between the words stays displayed, even when the ending
/// falls on the last word ( ai mangled, eu lucrat ).
List<Highlight> conjFormPieces(String v, String end) {
  if (end.isEmpty) return [Highlight(v, null)];
  final toks = v.split(' ');
  for (var j = toks.length - 1; j >= 0; j--) {
    if (toks[j].isEmpty) continue;
    final attempt = conjTokenPieces(toks[j], end);
    if (attempt.first.end != null) {
      final out = <Highlight>[];
      for (var m = 0; m < toks.length; m++) {
        if (m == j) {
          for (var q = 0; q < attempt.length; q++) {
            final p = attempt[q];
            out.add(q == 0 && j > 0
                ? Highlight(' ' + p.plain, p.end)
                : p);
          }
        } else {
          out.add(Highlight(m > 0 ? ' ' + toks[m] : toks[m], null));
        }
      }
      return out;
    }
  }
  return [Highlight(v, null)];
}

/// A meaning of a definition: optional label ( register, domain ) and
/// text.
class Meaning {
  final String label;
  final String text;
  Meaning(this.label, this.text);
}

/// The definition of a verb: one or several meanings, separated by
/// \u0003, optional label in front with \u0004.
List<Meaning> conjMeanings(String blob) {
  return blob.split('\u0003').map((tx) {
    final k = tx.indexOf('\u0004');
    if (k < 0) return Meaning('', tx);
    return Meaning(tx.substring(0, k), tx.substring(k + 1));
  }).toList();
}

/// Full forms per person: the stem glues on, the variants joined by a
/// slash; the empty field stays empty.
List<String> glueFullForms(String stem, List<String> a, int n) {
  final out = List.filled(n, '', growable: false);
  for (var i = 0; i < n; i++) {
    final f = (i < a.length && a[i].isNotEmpty) ? a[i] : '';
    out[i] = f.isEmpty ? '' : f.split('/').map((x) => stem + x).join('/');
  }
  return out;
}

/// English full forms: the empty field leaves the stem alone.
List<String> englishFullForms(String stem, List<String> a, int n) {
  final out = List.filled(n, '', growable: false);
  for (var i = 0; i < n; i++) {
    final f = (i < a.length && a[i].isNotEmpty) ? a[i] : '';
    out[i] = f.isEmpty ? stem : f.split('/').map((x) => stem + x).join('/');
  }
  return out;
}

/// The endings of a list of forms, by longest common prefix: each form
/// is cut after the beginning common to all the non-empty forms; the
/// cut keeps only the short remainders ( max ), a form that is itself
/// the common prefix or that departs from it is not highlighted.
List<String> conjCommonPrefixEnds(List<String> forms, {int max = 4}) {
  final full = forms.where((x) => x.isNotEmpty).toList();
  if (full.isEmpty) return const [];
  var p = full.first;
  for (final f in full) {
    while (p.isNotEmpty && !f.startsWith(p)) {
      p = p.substring(0, p.length - 1);
    }
  }
  if (p.isEmpty) return List.filled(forms.length, '');
  return forms
      .map((f) =>
          f.startsWith(p) && f.length > p.length && f.length - p.length <= max
              ? f.substring(p.length)
              : '')
      .toList();
}

/// The ending of a derived form ( participle, gerund ) when the
/// encoded stem does not explain it: the cut is made at the longest
/// common start with the infinitive, the short remainder is the
/// ending.
String conjDerivedEnd(String form, String verb, {int max = 3}) {
  if (form.isEmpty || form == verb) return '';
  var p = verb;
  while (p.isNotEmpty && !form.startsWith(p)) {
    p = p.substring(0, p.length - 1);
  }
  if (p.isEmpty) return '';
  final end = form.substring(p.length);
  return end.isNotEmpty && end.length <= max ? end : '';
}