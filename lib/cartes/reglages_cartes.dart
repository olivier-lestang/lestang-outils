/* Les reglages par carte, comme les modales du web ( france-modale.js,
   carte-monde-reglages.js, ueConf de carte-union.js ) : chaque groupe de
   couches et de points s allume ou s eteint, la carte du monde choisit
   son style ( ocean, nuit, encre, croquis ), son centrage ( meridien de
   Greenwich, Ameriques, Oceanie ) et ses villes marquees ; tout persiste
   aussitot dans les preferences.
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

/* les centrages de la carte du monde, ceux de la modale du web */
const centragesMonde = <double, String>{
  0.0: 'Méridien de Greenwich',
  -90.0: 'Amériques',
  180.0: 'Océanie',
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

/* le centrage de la carte du monde, meridien de Greenwich par defaut */
Future<double> lireCentrageMonde() async {
  final p = await SharedPreferences.getInstance();
  if (!p.containsKey('centrage-monde')) return 0.0;
  final v = p.getDouble('centrage-monde') ?? 0.0;
  return centragesMonde.containsKey(v) ? v : 0.0;
}

Future<void> ecrireCentrageMonde(double centrage) async {
  final p = await SharedPreferences.getInstance();
  await p.setDouble('centrage-monde', centrage);
}

/* les villes marquees de la carte du monde : seules les cachees sont
   persistees, toutes les autres restent affichees */
Future<Set<String>> lireVillesCachees() async {
  final p = await SharedPreferences.getInstance();
  return (p.getStringList('villes-monde-cachees') ?? const <String>[]).toSet();
}

Future<void> ecrireVillesCachees(Set<String> cachees) async {
  final p = await SharedPreferences.getInstance();
  await p.setStringList(
      'villes-monde-cachees', cachees.toList(growable: false)..sort());
}

/* la modale des reglages d une carte, comme sur le web : une case par
   groupe de couches, les styles et le centrage du monde en boutons
   radio, les villes marquees derriere leur propre boite ; chaque
   changement persiste aussitot, la carte se redessine derriere */
Future<void> modaleReglagesCarte(
    BuildContext context,
    String carte,
    Map<String, bool> groupes,
    String styleMonde,
    double centrageMonde,
    {void Function(String groupe, bool valeur)? change,
    void Function(String style)? changeStyle,
    void Function(double centrage)? changeCentrage,
    void Function()? choisirVilles}) async {
  var style = styleMonde;
  var centrage = centrageMonde;
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
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
                      child: Text('Centrage de la carte'),
                    ),
                    for (final c in centragesMonde.keys)
                      RadioListTile<double>(
                        title: Text(centragesMonde[c] ?? ''),
                        value: c,
                        groupValue: centrage,
                        onChanged: (valeur) {
                          if (valeur == null) return;
                          refeuille(() => centrage = valeur);
                          changeCentrage?.call(valeur);
                        },
                      ),
                    ListTile(
                      leading: const Icon(Icons.location_city),
                      title: const Text('Villes marquées'),
                      subtitle: const Text('Choisir les villes affichées'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: choisirVilles,
                    ),
                  ],
                  const SizedBox(height: 12),
                ]),
              )));
}

/* la boite des villes marquees du monde : une case par ville de la
   base, tout afficher et aucune d un coup ; chaque changement persiste
   aussitot */
Future<void> modaleVillesMonde(BuildContext context, List<String> noms,
    Set<String> cachees, void Function(Set<String> nouvelles) change) async {
  await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
          builder: (context, refeuille) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Text('Villes marquées',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                        '${noms.length - cachees.length} sur ${noms.length}'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(children: [
                      TextButton(
                          onPressed: () {
                            refeuille(() {});
                            change(<String>{});
                          },
                          child: const Text('Tout afficher')),
                      TextButton(
                          onPressed: () {
                            refeuille(() {});
                            change(noms.toSet());
                          },
                          child: const Text('Aucune')),
                    ]),
                  ),
                  Flexible(
                      child: ListView(shrinkWrap: true, children: [
                    for (final n in noms)
                      CheckboxListTile(
                        dense: true,
                        value: !cachees.contains(n),
                        title: Text(n),
                        onChanged: (coche) {
                          refeuille(() {});
                          final s = {...cachees};
                          if (coche ?? true) {
                            s.remove(n);
                          } else {
                            s.add(n);
                          }
                          change(s);
                        },
                      ),
                  ])),
                ]),
              )));
}