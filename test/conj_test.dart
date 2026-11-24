import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'package:lestang_outils/conj/moteurs.dart';

void main() {
  test('les six moteurs de conjugaison', _verifier);
}

void _verifier() {
  final data = jsonDecode(File('test/data.json').readAsStringSync())
      as Map<String, dynamic>;
  final jeux = <String, PlanchesConjug>{};
  for (final l in ['fr', 'en', 'es', 'de', 'it', 'pt', 'pl', 'cs']) {
    final d = data[l] as Map<String, dynamic>;
    jeux[l] = PlanchesConjug.depuis(l, d['tpl'] as String,
        d['verbs'] as String, d['defs'] as String, d['vsrc'] as String);
  }
  int ok = 0;
  void attendu(bool cond, String label) {
    if (!cond) {
      stderr.writeln('ECHEC: $label');
      exitCode = 1;
    } else {
      ok++;
    }
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
  attendu(cell('es', 'amar', 'Indicatif', 'présent', 0) == 'amo', 'es amo');
  final pc = cell('es', 'amar', 'Indicatif', 'passé composé', 0);
  attendu(pc == 'he amado', 'es he amado (obtenu: $pc)');
  final lvl = cell('es', 'alegrarse', 'Indicatif', 'présent', 0);
  attendu(lvl == 'me alegro', 'es me levanto (obtenu: $lvl)');

  // IT
  attendu(cell('it', 'capire', 'Indicativo', 'présent', 1) == 'capisci',
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
  final pnDe = cell('de', 'verstehen', 'Indicatif (Indikativ)', 'parfait', 2);
  attendu(pnDe == 'hat verstanden', 'de hat verstanden (obtenu: $pnDe)');
  final pnDe2 = cell('de', 'bringen', 'Indicatif (Indikativ)', 'parfait', 2);
  attendu(pnDe2 == 'hat gebracht', 'de hat gebracht (obtenu: $pnDe2)');
  attendu(cell('de', 'sein', 'Indicatif (Indikativ)', 'présent', 0) == 'bin',
      'de ich bin');
  attendu(jeux['de']!.definition('verstehen').isNotEmpty, 'de def verstehen');

  // comptes
  final comptes = {
    'fr': 8535,
    'en': 8339,
    'es': 8966,
    'de': 4220,
    'it': 6818,
    'pt': 4792,
    'pl': 9102,
    'cs': 4151
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
  attendu(cell('pl', 'pracować', 'Indicatif', 'présent', 1) == 'pracujesz',
      'pl pracujesz');
  attendu(cell('pl', 'pracować', 'Indicatif', 'futur', 0) == 'będę pracować',
      'pl będę pracować');
  attendu(cell('pl', 'pracować', 'Indicatif', 'passé', 4) == 'pracował' &&
      cell('pl', 'pracować', 'Indicatif', 'passé', 11) == 'pracowali' &&
      cell('pl', 'pracować', 'Indicatif', 'passé', 12) == 'pracowały',
      'pl passé pracować');
  attendu(cell('pl', 'pracować', 'Impératif', 'présent', 1) == 'pracujmy' &&
      cell('pl', 'pracować', 'Impératif', 'présent', 2) == 'pracujcie',
      'pl impératif pracować');
  attendu(cell('pl', 'być', 'Indicatif', 'présent', 5) == 'są', 'pl są');
  attendu(cell('pl', 'iść', 'Indicatif', 'passé', 4) == 'szedł' &&
      cell('pl', 'iść', 'Indicatif', 'passé', 5) == 'szła', 'pl passé iść');
  attendu(cell('cs', 'dělat', 'Indicatif', 'présent', 1) == 'děláš',
      'cs děláš');
  attendu(cell('cs', 'dělat', 'Indicatif', 'passé', 0) == 'dělal jsem',
      'cs passé dělat');
  attendu(cell('cs', 'dělat', 'Conditionnel', 'présent', 0) == 'dělal bych',
      'cs conditionnel dělat');
  attendu(cell('cs', 'být', 'Indicatif', 'présent', 5) == 'jsou', 'cs jsou');
  // verbes exceptionnels (formes verbatim du Wiktionary)
  attendu(cell('pl', 'zobaczyć', 'Indicatif', 'futur', 0) == 'zobaczę' &&
      cell('pl', 'zobaczyć', 'Indicatif', 'passé', 5) == 'zobaczyła',
      'pl zobaczyć');
  attendu(cell('pl', 'zobaczyć', 'Conditionnel', 'présent', 0) == 'zobaczyłbym',
      'pl conditionnel zobaczyć');
  attendu(cell('pl', 'wziąć', 'Indicatif', 'passé', 4) == 'wziął' &&
      cell('pl', 'wziąć', 'Conditionnel', 'présent', 7) == 'wzięlibyśmy',
      'pl wziąć');
  attendu(cell('cs', 'muset', 'Indicatif', 'présent', 0) == 'musím' &&
      cell('cs', 'muset', 'Indicatif', 'passé', 4) == 'musel',
      'cs muset');
  attendu(jeux['pl']!.definition('pracować').isNotEmpty, 'pl def pracować');
  attendu(jeux['cs']!.definition('dělat').isNotEmpty, 'cs def dělat');
  for (final e in {'fr': 1574, 'en': 6696, 'es': 3755, 'de': 3940,
      'it': 6339, 'pt': 4308}.entries) {
    final w = jeux[e.key]!
        .jeu
        .verbes
        .where((v) => jeux[e.key]!.sourceVerbe(v) == 'w')
        .length;
    attendu(w == e.value, '$e.key: $w verbes Wiktionary (attendu ${e.value})');
  }
  // 0 definition manquante ; lexique anglais limite aux verbes
  // definis par le Webster 1913 ( domaine public ) ; lexique
  // portugais limite aux verbes definis par le Figueiredo 1913 ;
  // lexique italien limite aux verbes definis par le Petrocchi 1887
  // ou la Crusca 1819 ( domaine public )
  // desormais limite aux verbes qu il definit, y compris les formes
  // doubles ( burn/spell/kneel ) ; le fantome « lambar » a ete retire.
  for (final e in {'en': 0, 'de': 0, 'it': 0, 'pt': 0}.entries) {
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
