import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lestang_outils/conj/engines.dart';

void main() {
  test('the conjugation engines', _verify);
}

void _verify() {
  final data =
      jsonDecode(File('test/data.json').readAsStringSync()) as Map<String, dynamic>;
  final games = <String, ConjugTables>{};
  for (final l in ['fr', 'en', 'es', 'de', 'it', 'pt', 'pl', 'cs', 'ro']) {
    final d = data[l] as Map<String, dynamic>;
    games[l] = ConjugTables.from(l, d['tpl'] as String, d['verbs'] as String,
        d['defs'] as String, d['vsrc'] as String);
  }
  int ok = 0;
  void expect_(bool cond, String label) {
    // fail() makes the suite fail : a FAILURE must never go unnoticed.
    if (!cond) fail(label);
    ok++;
  }

  String? cell(String l, String v, String moodName, String tenseName, int i,
      {bool clit = false}) {
    for (final m in games[l]!.render(v, clitic: clit)) {
      if (m.name != moodName) continue;
      for (final t in m.tenses) {
        if (t.name == tenseName) return i < t.val.length ? t.val[i] : null;
      }
    }
    return null;
  }

  // FR
  final pcFr = cell('fr', 'aimer', 'Indicatif', 'passé composé', 0);
  expect_(pcFr == 'ai aimé (aimée)', 'fr aimer PC (got: $pcFr)');
  expect_(cell('fr', 'aimer', 'Indicatif', 'présent', 0) == 'aime',
      'fr aimer présent');
  expect_(
      games['fr']!.header('aimer')['auxiliaire'] == 'avoir', 'fr aux avoir');
  expect_(games['fr']!.definition('aimer').isNotEmpty, 'fr def aimer');
  final cl = cell('fr', 'laver', 'Indicatif', 'présent', 0, clit: true);
  expect_(cl == 'me lave', 'fr se laver présent (got: $cl)');
  expect_(
      games['fr']!.header('aller')['auxiliaire'] == 'être', 'fr aller être');

  // EN
  final g = games['en']!.englishGrid('understand');
  expect_(g.length == 7, 'en grid 7 (${g.length})');
  final row = g.firstWhere((x) => x['verbe'] == 'understand');
  expect_(row['preterit'] == 'understood' && row['pp'] == 'understood',
      'en understand (got: ${row['preterit']}/${row['pp']})');
  // double -ed (US) / -t (GB) forms and a cleaned lexicon
  final gb = games['en']!
      .englishGrid('burn')
      .firstWhere((x) => x['verbe'] == 'burn', orElse: () => {});
  expect_(gb['preterit'] == 'burned (US) · burnt (GB)' &&
      gb['pp'] == 'burned (US) · burnt (GB)',
      'en burn (got: ${gb['preterit']}/${gb['pp']})');
  final sp = games['en']!
      .englishGrid('spell')
      .firstWhere((x) => x['verbe'] == 'spell', orElse: () => {});
  expect_(sp['pp'] == 'spelled (US) · spelt (GB)', 'en spell (got: ${sp['pp']})');
  final kn = games['en']!
      .englishGrid('kneel')
      .firstWhere((x) => x['verbe'] == 'kneel', orElse: () => {});
  expect_(kn['pp'] == 'kneeled (US) · knelt (GB)', 'en kneel (got: ${kn['pp']})');
  expect_(!games['en']!.set.verbs.any((v) => v.contains('-')),
      'en no verb with a hyphen');
  expect_(games['en']!.set.verbs.toSet().length == games['en']!.set.verbs.length,
      'en no duplicate');
  final longest = games['en']!.set.verbs
      .firstWhere((v) => v.length > 20, orElse: () => '.');
  expect_(longest == '.', 'en no verb longer than 20 letters ($longest)');

  // ES
  expect_(cell('es', 'amar', 'Indicativo', 'presente', 0) == 'amo', 'es amo');
  final pc = cell('es', 'amar', 'Indicativo', 'pretérito perfecto compuesto', 0);
  expect_(pc == 'he amado', 'es he amado (got: $pc)');
  final lvl = cell('es', 'alegrarse', 'Indicativo', 'presente', 0);
  expect_(lvl == 'me alegro', 'es me levanto (got: $lvl)');

  // IT
  expect_(cell('it', 'capire', 'Indicativo', 'presente', 1) == 'capisci',
      'it capisci');
  final pnIt = cell('it', 'venire', 'Indicativo', 'passato prossimo', 0);
  expect_(pnIt == 'sono venuto', 'it sono venuto (got: $pnIt)');
  expect_(games['it']!.definition('venire').isNotEmpty, 'it def venire');

  // PT
  final pnPt =
      cell('pt', 'falar', 'Indicativo', 'pretérito perfeito composto', 0);
  expect_(pnPt == 'tenho falado', 'pt tenho falado (got: $pnPt)');
  expect_(games['pt']!.definition('falar').isNotEmpty, 'pt def falar');

  // DE
  final pnDe = cell('de', 'verstehen', 'Indikativ', 'Perfekt', 2);
  expect_(pnDe == 'hat verstanden', 'de hat verstanden (got: $pnDe)');
  final pnDe2 = cell('de', 'bringen', 'Indikativ', 'Perfekt', 2);
  expect_(pnDe2 == 'hat gebracht', 'de hat gebracht (got: $pnDe2)');
  expect_(cell('de', 'sein', 'Indikativ', 'Präsens', 0) == 'bin', 'de ich bin');
  expect_(games['de']!.definition('verstehen').isNotEmpty, 'de def verstehen');

  // counts
  final counts = {
    'fr': 8535,
    'en': 19070,
    'es': 8957,
    'de': 4220,
    'it': 12429,
    'pt': 6084,
    'pl': 9064,
    'cs': 4143,
    'ro': 6970
  };
  for (final e in counts.entries) {
    expect_(games[e.key]!.set.verbs.length == e.value,
        '${e.key}: ${games[e.key]!.set.verbs.length} verbs (expected ${e.value})');
  }

  // source of each verb : 'w' Wiktionary, 'g' project generator
  expect_(games['fr']!.verbSource('être') == 'g', 'fr être generator');
  expect_(games['fr']!.verbSource('refaire') == 'w', 'fr refaire wiktionary');
  expect_(games['en']!.verbSource('be') == 'g', 'en be generator');
  expect_(games['es']!.verbSource('haber') == 'g', 'es haber generator');
  expect_(games['it']!.verbSource('essere') == 'g', 'it essere generator');
  expect_(games['pt']!.verbSource('ser') == 'g', 'pt ser generator');
  expect_(games['de']!.verbSource('machen') == 'g', 'de machen generator');
  expect_(games['pl']!.verbSource('być') == 'w', 'pl być wiktionary');

  // Polish and Czech : forms computed by the engines
  expect_(cell('pl', 'pracować', 'Tryb oznajmujący', 'czas teraźniejszy', 1) == 'pracujesz',
      'pl pracujesz');
  expect_(cell('pl', 'pracować', 'Tryb oznajmujący', 'czas przyszły', 0) == 'będę pracować',
      'pl będę pracować');
  expect_(cell('pl', 'pracować', 'Tryb oznajmujący', 'czas przeszły', 4) == 'pracował' &&
      cell('pl', 'pracować', 'Tryb oznajmujący', 'czas przeszły', 11) == 'pracowali' &&
      cell('pl', 'pracować', 'Tryb oznajmujący', 'czas przeszły', 12) == 'pracowały',
      'pl past pracować');
  expect_(cell('pl', 'pracować', 'Tryb rozkazujący', 'czas teraźniejszy', 1) == 'pracujmy' &&
      cell('pl', 'pracować', 'Tryb rozkazujący', 'czas teraźniejszy', 2) == 'pracujcie',
      'pl imperative pracować');
  expect_(cell('pl', 'być', 'Tryb oznajmujący', 'czas teraźniejszy', 5) == 'są', 'pl są');
  expect_(cell('pl', 'iść', 'Tryb oznajmujący', 'czas przeszły', 4) == 'szedł' &&
      cell('pl', 'iść', 'Tryb oznajmujący', 'czas przeszły', 5) == 'szła', 'pl past iść');
  expect_(cell('cs', 'dělat', 'Oznamovací způsob', 'přítomný', 1) == 'děláš',
      'cs děláš');
  expect_(cell('cs', 'dělat', 'Oznamovací způsob', 'minulý', 0) == 'dělal jsem',
      'cs past dělat');
  expect_(cell('cs', 'dělat', 'Podmiňovací způsob', 'přítomný', 0) == 'dělal bych',
      'cs conditional dělat');
  expect_(cell('cs', 'být', 'Oznamovací způsob', 'přítomný', 5) == 'jsou', 'cs jsou');
  // exceptional verbs (verbatim forms from the Wiktionary)
  expect_(cell('pl', 'zobaczyć', 'Tryb oznajmujący', 'czas przyszły', 0) == 'zobaczę' &&
      cell('pl', 'zobaczyć', 'Tryb oznajmujący', 'czas przeszły', 5) == 'zobaczyła',
      'pl zobaczyć');
  expect_(cell('pl', 'zobaczyć', 'Tryb przypuszczający', 'czas przeszły', 0) == 'zobaczyłbym',
      'pl conditional zobaczyć');
  expect_(cell('pl', 'wziąć', 'Tryb oznajmujący', 'czas przeszły', 4) == 'wziął' &&
      cell('pl', 'wziąć', 'Tryb przypuszczający', 'czas przeszły', 7) == 'wzięlibyśmy',
      'pl wziąć');
  expect_(cell('cs', 'muset', 'Oznamovací způsob', 'přítomný', 0) == 'musím' &&
      cell('cs', 'muset', 'Oznamovací způsob', 'minulý', 4) == 'musel',
      'cs muset');
  expect_(games['pl']!.definition('pracować').isNotEmpty, 'pl def pracować');
  expect_(games['cs']!.definition('dělat').isNotEmpty, 'cs def dělat');
  // native definitions of the monolingual Wiktionaries : default label
  expect_(
      games['pl']!.definition('pracować').first.label == 'pl. Wiktionary',
      'pl def pracowany native');
  expect_(
      games['cs']!.definition('dělat').first.label == 'cs. Wiktionary',
      'cs def dělat native');
  expect_(
      games['ro']!.definition('lucra').first.label == 'ro. Wiktionary',
      'ro def lucra native');

  // Romanian : verbatim forms from the Wiktionary, compounds computed
  expect_(cell('ro', 'lucra', 'Indicativ', 'prezent', 0) == 'lucrez',
      'ro lucrez');
  expect_(cell('ro', 'lucra', 'Indicativ', 'perfect compus', 0) == 'am lucrat',
      'ro am lucrat');
  expect_(cell('ro', 'lucra', 'Indicativ', 'viitor simplu', 0) == 'voi lucra',
      'ro voi lucra');
  expect_(
      cell('ro', 'lucra', 'Condițional prezent', '—', 0) == 'aș lucra',
      'ro aș lucra');
  expect_(cell('ro', 'fi', 'Indicativ', 'prezent', 0) == 'sunt', 'ro fi sunt');
  expect_(
      games['ro']!.set.defs.containsKey('lucra') &&
          games['ro']!.definition('lucra').isNotEmpty,
      'ro def lucra');
  for (final e in {
    'fr': 1574,
    'en': 17427,
    'es': 3746,
    'de': 3940,
    'it': 11950,
    'pt': 5600
  }.entries) {
    final w = games[e.key]!
        .set
        .verbs
        .where((v) => games[e.key]!.verbSource(v) == 'w')
        .length;
    expect_(w == e.value, '$e.key: $w wiktionary verbs (expected ${e.value})');
  }
  // 0 missing definition in every language : verbs without a definition
  // were filled from the monolingual Wiktionaries ( fr, en, es, pl, cs )
  // or, failing that, from the English gloss of the English Wiktionary ;
  // the 60 words that no Wiktionary defines as a verb ( hygiene,
  // datagram, turbate, twilly, indigest in English... ) were removed.
  for (final e in {
    'fr': 0,
    'en': 0,
    'es': 0,
    'de': 0,
    'it': 0,
    'pt': 0,
    'pl': 0,
    'cs': 0,
    'ro': 0
  }.entries) {
    final missing = games[e.key]!
        .set
        .verbs
        .where((v) => !games[e.key]!.set.defs.containsKey(v))
        .length;
    expect_(missing == e.value,
        '${e.key}: $missing missing defs (expected ${e.value})');
  }

  // suggestions
  expect_(
      games['fr']!.set.suggest('aim').contains('aimer'), 'fr suggestions');
  print('TESTS OK: $ok');
}