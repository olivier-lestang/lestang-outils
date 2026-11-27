/* The per-map settings, like the dialogs of the web ( france-modale.js,
   carte-monde-reglages.js, ueConf of carte-union.js ): each group of
   layers and points switches on and off, the world map chooses its
   style ( ocean, night, ink, sketch ), its center ( Greenwich
   meridian, Americas, Oceania ) and its marked cities; everything
   persists at once in the preferences.
   SPDX-License-Identifier: MIT. */
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/* a settings group: the title heads the dialog section, the layers
   and points are the database keys it commands */
class CardGroup {
  final String title;
  final List<String> layers;
  final List<String> points;
  const CardGroup(this.title,
      {this.layers = const [], this.points = const []});
}

/* the groups of each map, those of the web dialogs */
const cardGroups = <String, Map<String, CardGroup>>{
  'france': {
    'departements': CardGroup('Départements et régions',
        layers: ['departements', 'contour']),
    'autoroutes': CardGroup('Autoroutes', layers: ['autoroutes']),
    'nationales': CardGroup('Nationales', layers: ['nationales']),
    'departementales': CardGroup('Départementales',
        layers: ['departementales']),
    'lgv': CardGroup('Lignes à grande vitesse',
        layers: ['lgv'], points: ['lgv-stations']),
    'fleuves': CardGroup('Fleuves', layers: ['fleuves']),
    'zee': CardGroup('Eaux territoriales', layers: ['zee']),
    'villes': CardGroup('Villes',
        points: ['grandes-villes', 'chefs-lieux', 'villes']),
    'transports': CardGroup('Transports en Île-de-France',
        layers: ['paris', 'villes-transports'],
        points: ['stations', 'paris-stations']),
  },
  'union': {
    'membres': CardGroup('États membres', layers: ['membres']),
    'autres': CardGroup('Autres pays',
        layers: ['hors-ue', 'hors-ue-2', 'hors-ue-3', 'autres']),
    'zee': CardGroup('Eaux territoriales', layers: ['zee']),
    'fleuves': CardGroup('Fleuves', layers: ['fleuves', 'grands-fleuves']),
    'eroutes': CardGroup('Routes européennes', layers: ['eroutes']),
    'voisins': CardGroup('Routes des pays voisins',
        layers: ['routes-voisins-brutes']),
    'lgv': CardGroup('Lignes à grande vitesse',
        layers: ['lgv'], points: ['lgv-stations']),
    'capitales': CardGroup('Capitales', points: ['capitales']),
    'villes': CardGroup('Villes', points: ['villes']),
    'panonceaux': CardGroup('Panonceaux des routes',
        points: ['refs-aut', 'refs-rn', 'refs-rd', 'refs-er']),
  },
  'monde': {
    'nuit': CardGroup('Zone de nuit (ensoleillement)'),
    'frontieres': CardGroup('Frontières et terres', layers: ['frontieres']),
    'villes': CardGroup('Villes', points: ['villes']),
  },
};

/* the styles of the world map, those of WM_STYLES of the web */
const styleLabels = <String, String>{
  'ocean': 'Océan',
  'nuit': 'Nuit',
  'encre': 'Encre',
  'croquis': 'Croquis',
};

/* the centers of the world map, those of the web dialog; a small class
   rather than a double-keyed map: Dart refuses doubles as keys of a
   const map */
class WorldCenter {
  final double value;
  final String title;
  const WorldCenter(this.value, this.title);
}

const worldCenters = <WorldCenter>[
  WorldCenter(0.0, 'Méridien de Greenwich'),
  WorldCenter(-90.0, 'Amériques'),
  WorldCenter(180.0, 'Océanie'),
];

/* does the key of a layer or of a point group belong to a lit group?
   a key outside every group stays visible */
bool groupVisible(String map, String key, Map<String, bool> groups) {
  for (final e
      in (cardGroups[map] ?? const <String, CardGroup>{}).entries) {
    if (e.value.layers.contains(key) || e.value.points.contains(key)) {
      return groups[e.key] ?? true;
    }
  }
  return true;
}

/* the persisted visibilities of a map: one boolean per group, all lit
   by default */
Future<Map<String, bool>> readVisibility(String map) async {
  final p = await SharedPreferences.getInstance();
  final m = <String, bool>{};
  for (final g in (cardGroups[map] ?? const <String, CardGroup>{}).keys) {
    m[g] = p.getBool('visibilite-$map-$g') ?? true;
  }
  return m;
}

Future<void> writeVisibility(String map, String group, bool value) async {
  final p = await SharedPreferences.getInstance();
  await p.setBool('visibilite-$map-$group', value);
}

/* the style of the world map, ocean by default */
Future<String> readWorldStyle() async {
  final p = await SharedPreferences.getInstance();
  final s = p.getString('style-monde') ?? 'ocean';
  return styleLabels.containsKey(s) ? s : 'ocean';
}

Future<void> writeWorldStyle(String style) async {
  final p = await SharedPreferences.getInstance();
  await p.setString('style-monde', style);
}

/* the center of the world map, Greenwich meridian by default */
Future<double> readWorldCenter() async {
  final p = await SharedPreferences.getInstance();
  if (!p.containsKey('centrage-monde')) return 0.0;
  final v = p.getDouble('centrage-monde') ?? 0.0;
  return worldCenters.any((c) => c.value == v) ? v : 0.0;
}

Future<void> writeWorldCenter(double center) async {
  final p = await SharedPreferences.getInstance();
  await p.setDouble('centrage-monde', center);
}

/* the marked cities of the world map: only the hidden ones persist,
   all the others stay displayed */
Future<Set<String>> readHiddenCities() async {
  final p = await SharedPreferences.getInstance();
  return (p.getStringList('villes-monde-cachees') ?? const <String>[]).toSet();
}

Future<void> writeHiddenCities(Set<String> hidden) async {
  final p = await SharedPreferences.getInstance();
  await p.setStringList(
      'villes-monde-cachees', hidden.toList(growable: false)..sort());
}

/* the settings dialog of a map, like on the web: one switch per group
   of layers, the styles and the center of the world as radio buttons,
   the marked cities behind their own box; every change persists at
   once, the map redraws behind */
Future<void> mapSettingsDialog(
    BuildContext context,
    String map,
    Map<String, bool> groups,
    String worldStyle,
    double worldCenter, {
    void Function(String group, bool value)? onChanged,
    void Function(String style)? onStyleChanged,
    void Function(double center)? onCenterChanged,
    void Function()? onPickCities,
  }) async {
  var style = worldStyle;
  var center = worldCenter;
  await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
          builder: (context, setSheet) => SafeArea(
                child: ListView(shrinkWrap: true, children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Text('Réglages de la carte',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  for (final e
                      in (cardGroups[map] ?? const <String, CardGroup>{})
                          .entries)
                    SwitchListTile(
                      title: Text(e.value.title),
                      value: groups[e.key] ?? true,
                      onChanged: (value) {
                        setSheet(() {});
                        onChanged?.call(e.key, value);
                      },
                    ),
                  if (map == 'monde') ...[
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
                      child: Text('Style de la carte'),
                    ),
                    for (final s in styleLabels.keys)
                      RadioListTile<String>(
                        title: Text(styleLabels[s] ?? s),
                        value: s,
                        groupValue: style,
                        onChanged: (value) {
                          if (value == null) return;
                          setSheet(() => style = value);
                          onStyleChanged?.call(value);
                        },
                      ),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
                      child: Text('Centrage de la carte'),
                    ),
                    for (final c in worldCenters)
                      RadioListTile<double>(
                        title: Text(c.title),
                        value: c.value,
                        groupValue: center,
                        onChanged: (value) {
                          if (value == null) return;
                          setSheet(() => center = value);
                          onCenterChanged?.call(value);
                        },
                      ),
                    ListTile(
                      leading: const Icon(Icons.location_city),
                      title: const Text('Villes marquées'),
                      subtitle: const Text('Choisir les villes affichées'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: onPickCities,
                    ),
                  ],
                  const SizedBox(height: 12),
                ]),
              )));
}

/* the box of the marked cities of the world: one checkbox per city of
   the database, show all and none at once; every change persists at
   once */
Future<void> worldCitiesDialog(BuildContext context, List<String> names,
    Set<String> hidden, void Function(Set<String> updated) onChange) async {
  await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
          builder: (context, setSheet) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Text('Villes marquées',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                        '${names.length - hidden.length} sur ${names.length}'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(children: [
                      TextButton(
                          onPressed: () {
                            setSheet(() {});
                            onChange(<String>{});
                          },
                          child: const Text('Tout afficher')),
                      TextButton(
                          onPressed: () {
                            setSheet(() {});
                            onChange(names.toSet());
                          },
                          child: const Text('Aucune')),
                    ]),
                  ),
                  Flexible(
                      child: ListView(shrinkWrap: true, children: [
                    for (final n in names)
                      CheckboxListTile(
                        dense: true,
                        value: !hidden.contains(n),
                        title: Text(n),
                        onChanged: (checked) {
                          setSheet(() {});
                          final s = {...hidden};
                          if (checked ?? true) {
                            s.remove(n);
                          } else {
                            s.add(n);
                          }
                          onChange(s);
                        },
                      ),
                  ])),
                ]),
              )));
}