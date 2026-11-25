/* Le registre des cartes : une entree par carte de l application, l ordre
   persiste dans les preferences. SPDX-License-Identifier : MIT. */
import 'package:shared_preferences/shared_preferences.dart';

/* les cles servent aussi de libelles dans le glossaire */
const clesCartes = <String>[
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

Future<List<String>> lireOrdre() async {
  final p = await SharedPreferences.getInstance();
  final cru = p.getStringList('ordre-cartes') ?? const [];
  /* les cles inconnues tombent, les nouvelles cartes se rangent a la fin */
  final filtres = cru.where(clesCartes.contains).toList();
  for (final c in clesCartes) {
    if (!filtres.contains(c)) filtres.add(c);
  }
  return filtres;
}

Future<void> ecrireOrdre(List<String> ordre) async {
  final p = await SharedPreferences.getInstance();
  await p.setStringList('ordre-cartes', ordre);
}
