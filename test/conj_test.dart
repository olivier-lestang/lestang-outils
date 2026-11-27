import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'package:lestang_outils/conj/moteurs.dart';

void main() {
  test('les moteurs de conjugaison', _verifier);
}

void _verifier() {
  final data = jsonDecode(File('test/data.json').readAsStringSync())
      as Map<String, dynamic>;
  final jeux = <String, PlanchesConjug>{};
  for (final l in ['fr', 'en', 'es', 'de', 'it', 'pt', 'pl', 'cs', 'ro']) {
    final d = data[l] as Map<String, dynamic>;
    jeux[l] = PlanchesConjug.depuis(l, d['tpl'] as String,
        d['verbs'] as String, d['defs'] as String, d['vsrc'] as String);
  }
  int ok = 0;
  void attendu(bool cond, String label) {
    // fail() fait echouer la suite : un ECHEC ne doit jamais passer inapercu.
    if (!cond) fail(label);
    ok++;
  }

  String? cell(String l, String v, String modeNom, String tempsNom, int i,
      {bool clit = false}) {
    for (final m in jeux[l]!.rend(v, clit: clit)) {
      if (m.nom != modeNom) continue;
      for (final t in m.temps) {
        if (t.nom == tempsNom) return i < t.val.length ? t.val[i] : null;
      }
    }
    return null;
  }

  // FR
  final pcFr = cell('fr', 'aimer', 'Indicatif', 'passé composé', 0);
  attendu(pcFr == 'ai aimé (aimée)', 'fr aimer PC (obtenu: $pcFr)');
  attendu(cell('fr', 'aimer', 'Indicatif', 'présent', 0) == 'aime',
      'fr aimer présent');
  attendu(
      jeux['fr']!.chapeau('aimer')['auxiliaire'] == 'avoir', 'fr aux avoir');
  attendu(jeux['fr']!.definition('aimer').isNotEmpty, 'fr def aimer');
  final cl = cell('fr', 'laver', 'Indicatif', 'présent', 0, clit: true);
  attendu(cl == 'me lave', 'fr se laver présent (obtenu: $cl)');
  attendu(
      jeux['fr']!.chapeau('aller')['auxiliaire'] == 'être', 'fr aller être');

  // EN
  final g = jeux['en']!.grilleEn('understand');
  attendu(g.length == 7, 'en grille 7 (${g.length})');
  final ligne = g.firstWhere((x) => x['verbe'] == 'understand');
  attendu(ligne['preterit'] == 'understood' && ligne['pp'] == 'understood',
      'en understand (obtenu: ${ligne['preterit']}/${ligne['pp']})');
  // doubles formes -ed (US) / -t (GB) et lexique nettoye
  final gb = jeux['en']!.grilleEn('burn')
      .firstWhere((x) => x['verbe'] == 'burn', orElse: () => {});
  attendu(gb['preterit'] == 'burned (US) · burnt (GB)' &&
      gb['pp'] == 'burned (US) · burnt (GB)',
      'en burn (obtenu: ${gb['preterit']}/${gb['pp']})');
  final sp = jeux['en']!.grilleEn('spell')
      .firstWhere((x) => x['verbe'] == 'spell', orElse: () => {});
  attendu(sp['pp'] == 'spelled (US) · spelt (GB)',
      'en spell (obtenu: ${sp['pp']})');
  final kn = jeux['en']!.grilleEn('kneel')
      .firstWhere((x) => x['verbe'] == 'kneel', orElse: () => {});
  attendu(kn['pp'] == 'kneeled (US) · knelt (GB)',
      'en kneel (obtenu: ${kn['pp']})');
  attendu(!jeux['en']!.jeu.verbes.any((v) => v.contains('-')),
      'en aucun verbe a trait d union');
  attendu(jeux['en']!.jeu.verbes.toSet().length == jeux['en']!.jeu.verbes.length,
      'en aucun doublon');
  final fleuv = jeux['en']!.jeu.verbes
      .firstWhere((v) => v.length > 20, orElse: () => '.');
  attendu(fleuv == '.', 'en aucun verbe de plus de 20 lettres ($fleuv)');

  // ES
  attendu(cell('es', 'amar', 'Indicativo', 'presente', 0) == 'amo', 'es amo');
  final pc = cell('es', 'amar', 'Indicativo', 'pretérito perfecto compuesto', 0);
  attendu(pc == 'he amado', 'es he amado (obtenu: $pc)');
  final lvl = cell('es', 'alegrarse', 'Indicativo', 'presente', 0);
  attendu(lvl == 'me alegro', 'es me levanto (obtenu: $lvl)');

  // IT
  attendu(cell('it', 'capire', 'Indicativo', 'presente', 1) == 'capisci',
      'it capisci');
  final pnIt = cell('it', 'venire', 'Indicativo', 'passato prossimo', 0);
  attendu(pnIt == 'sono venuto', 'it sono venuto (obtenu: $pnIt)');
  attendu(jeux['it']!.definition('venire').isNotEmpty, 'it def venire');

  // PT
  final pnPt =
      cell('pt', 'falar', 'Indicativo', 'pretérito perfeito composto', 0);
  attendu(pnPt == 'tenho falado', 'pt tenho falado (obtenu: $pnPt)');
  attendu(jeux['pt']!.definition('falar').isNotEmpty, 'pt def falar');

  // DE
  final pnDe = cell('de', 'verstehen', 'Indikativ', 'Perfekt', 2);
  attendu(pnDe == 'hat verstanden', 'de hat verstanden (obtenu: $pnDe)');
  final pnDe2 = cell('de', 'bringen', 'Indikativ', 'Perfekt', 2);
  attendu(pnDe2 == 'hat gebracht', 'de hat gebracht (obtenu: $pnDe2)');
  attendu(cell('de', 'sein', 'Indikativ', 'Präsens', 0) == 'bin',
      'de ich bin');
  attendu(jeux['de']!.definition('verstehen').isNotEmpty, 'de def verstehen');

  // comptes
  final comptes = {
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
  for (final e in comptes.entries) {
    attendu(jeux[e.key]!.jeu.verbes.length == e.value,
        '${e.key}: ${jeux[e.key]!.jeu.verbes.length} verbes (attendu ${e.value})');
  }

  // source de chaque verbe : 'w' Wiktionary, 'g' generateur du projet
  attendu(jeux['fr']!.sourceVerbe('être') == 'g', 'fr être generateur');
  attendu(jeux['fr']!.sourceVerbe('refaire') == 'w', 'fr refaire wiktionary');
  attendu(jeux['en']!.sourceVerbe('be') == 'g', 'en be generateur');
  attendu(jeux['es']!.sourceVerbe('haber') == 'g', 'es haber generateur');
  attendu(jeux['it']!.sourceVerbe('essere') == 'g', 'it essere generateur');
  attendu(jeux['pt']!.sourceVerbe('ser') == 'g', 'pt ser generateur');
  attendu(jeux['de']!.sourceVerbe('machen') == 'g', 'de machen generateur');
  attendu(jeux['pl']!.sourceVerbe('być') == 'w', 'pl être wiktionary');

  // polonais et tcheque : formes calculees par les moteurs
  attendu(cell('pl', 'pracować', 'Tryb oznajmujący', 'czas teraźniejszy', 1) == 'pracujesz',
      'pl pracujesz');
  attendu(cell('pl', 'pracować', 'Tryb oznajmujący', 'czas przyszły', 0) == 'będę pracować',
      'pl będę pracować');
  attendu(cell('pl', 'pracować', 'Tryb oznajmujący', 'czas przeszły', 4) == 'pracował' &&
      cell('pl', 'pracować', 'Tryb oznajmujący', 'czas przeszły', 11) == 'pracowali' &&
      cell('pl', 'pracować', 'Tryb oznajmujący', 'czas przeszły', 12) == 'pracowały',
      'pl passé pracować');
  attendu(cell('pl', 'pracować', 'Tryb rozkazujący', 'czas teraźniejszy', 1) == 'pracujmy' &&
      cell('pl', 'pracować', 'Tryb rozkazujący', 'czas teraźniejszy', 2) == 'pracujcie',
      'pl impératif pracować');
  attendu(cell('pl', 'być', 'Tryb oznajmujący', 'czas teraźniejszy', 5) == 'są', 'pl są');
  attendu(cell('pl', 'iść', 'Tryb oznajmujący', 'czas przeszły', 4) == 'szedł' &&
      cell('pl', 'iść', 'Tryb oznajmujący', 'czas przeszły', 5) == 'szła', 'pl passé iść');
  attendu(cell('cs', 'dělat', 'Oznamovací způsob', 'přítomný', 1) == 'děláš',
      'cs děláš');
  attendu(cell('cs', 'dělat', 'Oznamovací způsob', 'minulý', 0) == 'dělal jsem',
      'cs passé dělat');
  attendu(cell('cs', 'dělat', 'Podmiňovací způsob', 'přítomný', 0) == 'dělal bych',
      'cs conditionnel dělat');
  attendu(cell('cs', 'být', 'Oznamovací způsob', 'přítomný', 5) == 'jsou', 'cs jsou');
  // verbes exceptionnels (formes verbatim du Wiktionary)
  attendu(cell('pl', 'zobaczyć', 'Tryb oznajmujący', 'czas przyszły', 0) == 'zobaczę' &&
      cell('pl', 'zobaczyć', 'Tryb oznajmujący', 'czas przeszły', 5) == 'zobaczyła',
      'pl zobaczyć');
  attendu(cell('pl', 'zobaczyć', 'Tryb przypuszczający', 'czas przeszły', 0) == 'zobaczyłbym',
      'pl conditionnel zobaczyć');
  attendu(cell('pl', 'wziąć', 'Tryb oznajmujący', 'czas przeszły', 4) == 'wziął' &&
      cell('pl', 'wziąć', 'Tryb przypuszczający', 'czas przeszły', 7) == 'wzięlibyśmy',
      'pl wziąć');
  attendu(cell('cs', 'muset', 'Oznamovací způsob', 'přítomný', 0) == 'musím' &&
      cell('cs', 'muset', 'Oznamovací způsob', 'minulý', 4) == 'musel',
      'cs muset');
  attendu(jeux['pl']!.definition('pracować').isNotEmpty, 'pl def pracować');
  attendu(jeux['cs']!.definition('dělat').isNotEmpty, 'cs def dělat');
  // definitions natives des Wiktionary monolingues : etiquette par defaut
  attendu(
      jeux['pl']!.definition('pracować').first.etiquette == 'pl. Wiktionary',
      'pl def pracowany native');
  attendu(
      jeux['cs']!.definition('dělat').first.etiquette == 'cs. Wiktionary',
      'cs def dělat native');
  attendu(
      jeux['ro']!.definition('lucra').first.etiquette == 'ro. Wiktionary',
      'ro def lucra native');

  // roumain : formes verbatim du Wiktionary, composes calcules
  attendu(cell('ro', 'lucra', 'Indicativ', 'prezent', 0) == 'lucrez',
      'ro lucrez');
  attendu(cell('ro', 'lucra', 'Indicativ', 'perfect compus', 0) == 'am lucrat',
      'ro am lucrat');
  attendu(cell('ro', 'lucra', 'Indicativ', 'viitor simplu', 0) == 'voi lucra',
      'ro voi lucra');
  attendu(
      cell('ro', 'lucra', 'Condițional prezent', '—', 0) == 'aș lucra',
      'ro aș lucra');
  attendu(cell('ro', 'fi', 'Indicativ', 'prezent', 0) == 'sunt',
      'ro fi sunt');
  attendu(
      jeux['ro']!.jeu.defs.containsKey('lucra') &&
          jeux['ro']!.definition('lucra').isNotEmpty,
      'ro def lucra');
  for (final e in {'fr': 1574, 'en': 17427, 'es': 3746, 'de': 3940,
      'it': 11950, 'pt': 5600}.entries) {
    final w = jeux[e.key]!
        .jeu
        .verbes
        .where((v) => jeux[e.key]!.sourceVerbe(v) == 'w')
        .length;
    attendu(w == e.value, '$e.key: $w verbes Wiktionary (attendu ${e.value})');
  }
  // 0 definition manquante dans toutes les langues : les verbes sans
  // definition ont ete combles depuis les Wiktionary monolingues
  // ( fr, en, es, pl, cs ) ou, a defaut, le glossaire anglais du
  // Wiktionary anglophone ; les 60 mots qu aucun Wiktionary ne
  // definit comme verbe ( hygiene, datagram, turbate, twilly,
  // indigest en anglais... ) ont ete retires.
  for (final e in {'fr': 0, 'en': 0, 'es': 0, 'de': 0, 'it': 0,
      'pt': 0, 'pl': 0, 'cs': 0, 'ro': 0}.entries) {
    final manq = jeux[e.key]!
        .jeu
        .verbes
        .where((v) => !jeux[e.key]!.jeu.defs.containsKey(v))
        .length;
    attendu(manq == e.value,
        '${e.key}: $manq defs manquantes (attendu ${e.value})');
  }

  // suggestions
  attendu(
      jeux['fr']!.jeu.suggestions('aim').contains('aimer'), 'fr suggestions');
  print('TESTS OK: $ok');
}
