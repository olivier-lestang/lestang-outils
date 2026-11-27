/* The card registry: one entry per card of the application, the order
   persists in the preferences. SPDX-License-Identifier: MIT. */
import 'package:shared_preferences/shared_preferences.dart';

/* the keys also serve as labels in the glossary */
const cardKeys = <String>[
  'conj-fr',
  'conj-en',
  'conj-es',
  'conj-de',
  'conj-it',
  'conj-pt',
  'conj-pl',
  'conj-cs',
  'conj-ro',
  'france',
  'union',
  'monde',
  'météo',
  'pdf',
  'recherche',
  'raccourcis',
  'motdepasse',
  'réglages',
  'infos',
];

Future<List<String>> readOrder() async {
  final p = await SharedPreferences.getInstance();
  final raw = p.getStringList('ordre-cartes') ?? const [];
  /* unknown keys drop out, new cards line up at the end */
  final filtered = raw.where(cardKeys.contains).toList();
  for (final c in cardKeys) {
    if (!filtered.contains(c)) filtered.add(c);
  }
  return filtered;
}

Future<void> writeOrder(List<String> order) async {
  final p = await SharedPreferences.getInstance();
  await p.setStringList('ordre-cartes', order);
}