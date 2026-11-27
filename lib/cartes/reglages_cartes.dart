/* Les reglages par carte, comme les modales du web ( france-modale.js,
   carte-monde-reglages.js, ueConf de carte-union.js ) : chaque groupe de
   couches et de points s allume ou s eteint, la carte du monde choisit
   son style ( ocean, nuit, encre, croquis ) et sa zone de nuit ; tout
   persiste aussitot dans les preferences.
   SPDX-License-Identifier : MIT. */
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/* un groupe de reglage : le libelle sert de titre dans la modale, les
   couches et les points sont les cles de la base qu il commande */
class GroupeCarte {
  final String libelle;
  final List<String> couches;
  final List<String> points;
  const GroupeCarte(this.libelle, {this.couches = const [], this.points = const []});
}

/* les groupes de chaque carte, ceux des modales du web */
const groupesCarte = <String, Map<String, GroupeCarte>>{
  'france': {
    'departements': GroupeCarte('Départements et régions',
        couches: ['departements', 'contour']),
    'autoroutes': GroupeCarte('Autoroutes', couches: ['autoroutes']),
    'nationales': GroupeCarte('Nationales', couches: ['nationales']),
    'departementales': GroupeCarte('Départementales',
        couches: ['departementales']),
    'lgv': GroupeCarte('Lignes à grande vitesse',
        couches: ['lgv'], points: ['lgv-stations']),
    'fleuves': GroupeCarte('Fleuves', couches: ['fleuves']),
    'zee': GroupeCarte('Eaux territoriales', couches: ['zee']),
    'villes': GroupeCarte('Villes',
        points: ['grandes-villes', 'chefs-lieux', 'villes']),
    'transports': GroupeCarte('Transports en Île-de-France',
        couches: ['paris', 'villes-transports'],
        points: ['stations', 'paris-stations']),
  },
  'union': {
    'membres': GroupeCarte('États membres', couches: ['membres']),
    'autres': GroupeCarte('Autres pays',
        couches: ['hors-ue', 'hors-ue-2', 'hors-ue-3', 'autres']),
    'zee': GroupeCarte('Eaux territoriales', couches: ['zee']),
    'fleuves': GroupeCarte('Fleuves', couches: ['fleuves', 'grands-fleuves']),
    'eroutes': GroupeCarte('Routes européennes', couches: ['eroutes']),
    'voisins': GroupeCarte('Routes des pays voisins',
        couches: ['routes-voisins-brutes']),
    'lgv': GroupeCarte('Lignes à grande vitesse',
        couches: ['lgv'], points: ['lgv-stations']),
    'capitales': GroupeCarte('Capitales', points: ['capitales']),
    'villes': GroupeCarte('Villes', points: ['villes']),
    'panonceaux': GroupeCarte('Panonceaux des routes',
        points: ['refs-aut', 'refs-rn', 'refs-rd', 'refs-er']),
  },
  'monde': {
    'nuit': GroupeCarte('Zone de nuit (ensoleillement)'),
    'frontieres': GroupeCarte('Frontières et terres', couches: ['frontieres']),
    'villes': GroupeCarte('Villes', points: ['villes']),
  },
};

/* les styles de la carte du monde, ceux de WM_STYLES du web */
const libellesStyles = <String, String>{
  'ocean': 'Océan',
  'nuit': 'Nuit',
  'encre': 'Encre',
  'croquis': 'Croquis',
};

/* la cle d une couche ou d un groupe de points appartient-elle a un
   groupe allume ? une cle hors de tout groupe reste visible */
bool visible(String carte, String cle, Map<String, bool> groupes) {
  for (final e
      in (groupesCarte[carte] ?? const <String, GroupeCarte>{}).entries) {
    if (e.value.couches.contains(cle) || e.value.points.contains(cle)) {
      return groupes[e.key] ?? true;
    }
  }
  return true;
}

/* les visibilites persistees d une carte : un booleen par groupe, tous
   allumes par defaut */
Future<Map<String, bool>> lireVisibilites(String carte) async {
  final p = await SharedPreferences.getInstance();
  final m = <String, bool>{};
  for (final g in (groupesCarte[carte] ?? const <String, GroupeCarte>{}).keys) {
    m[g] = p.getBool('visibilite-$carte-$g') ?? true;
  }
  return m;
}

Future<void> ecrireVisibilite(String carte, String groupe, bool valeur) async {
  final p = await SharedPreferences.getInstance();
  await p.setBool('visibilite-$carte-$groupe', valeur);
}

/* le style de la carte du monde, ocean par defaut */
Future<String> lireStyleMonde() async {
  final p = await SharedPreferences.getInstance();
  final s = p.getString('style-monde') ?? 'ocean';
  return libellesStyles.containsKey(s) ? s : 'ocean';
}

Future<void> ecrireStyleMonde(String style) async {
  final p = await SharedPreferences.getInstance();
  await p.setString('style-monde', style);
}

/* la modale des reglages d une carte, comme sur le web : une case par
   groupe de couches, les styles du monde en boutons radio ; chaque
   changement persiste aussitot, la carte se redessine derriere */
Future<void> modaleReglagesCarte(
    BuildContext context,
    String carte,
    Map<String, bool> groupes,
    String styleMonde,
    {void Function(String groupe, bool valeur)? change,
    void Function(String style)? changeStyle}) async {
  var style = styleMonde;
  await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
          builder: (context, refeuille) => SafeArea(
                child: ListView(shrinkWrap: true, children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Text('Réglages de la carte',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  for (final e
                      in (groupesCarte[carte] ?? const <String, GroupeCarte>{})
                          .entries)
                    SwitchListTile(
                      title: Text(e.value.libelle),
                      value: groupes[e.key] ?? true,
                      onChanged: (valeur) {
                        refeuille(() {});
                        change?.call(e.key, valeur);
                      },
                    ),
                  if (carte == 'monde') ...[
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
                      child: Text('Style de la carte'),
                    ),
                    for (final s in libellesStyles.keys)
                      RadioListTile<String>(
                        title: Text(libellesStyles[s] ?? s),
                        value: s,
                        groupValue: style,
                        onChanged: (valeur) {
                          if (valeur == null) return;
                          refeuille(() => style = valeur);
                          changeStyle?.call(valeur);
                        },
                      ),
                  ],
                  const SizedBox(height: 12),
                ]),
              )));
}