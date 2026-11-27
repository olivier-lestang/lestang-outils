/* The per-map settings, like the dialogs of the web ( france-modale.js,
   carte-monde-reglages.js, ueConf of carte-union.js ): each group of
   layers and points switches on and off, the world map chooses its
   style ( ocean, night, ink, sketch ), its center ( Greenwich
   meridian, Americas, Oceania ) and its marked cities; everything
   persists at once in the preferences.
   SPDX-License-Identifier: MIT. */
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n.dart' show translate;
import 'world_map.dart' show disputedGroups;

/* a settings group: the title heads the dialog section ( a key of the
   glossary, the French text is the fallback ), the layers and points
   are the database keys it commands */
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
    'departements': CardGroup('grp-departements',
        layers: ['departements', 'contour']),
    'autoroutes': CardGroup('grp-autoroutes', layers: ['autoroutes']),
    'nationales': CardGroup('grp-nationales', layers: ['nationales']),
    'departementales': CardGroup('grp-departementales',
        layers: ['departementales']),
    'lgv': CardGroup('grp-lgv',
        layers: ['lgv'], points: ['lgv-stations']),
    'fleuves': CardGroup('grp-fleuves', layers: ['fleuves']),
    'zee': CardGroup('grp-zee', layers: ['zee']),
    'villes': CardGroup('grp-villes',
        points: ['grandes-villes', 'chefs-lieux', 'villes']),
    'transports': CardGroup('grp-transports',
        layers: ['paris', 'villes-transports'],
        points: ['stations', 'paris-stations']),
  },
  'union': {
    'membres': CardGroup('grp-membres', layers: ['membres']),
    'autres': CardGroup('grp-autres',
        layers: ['hors-ue', 'hors-ue-2', 'hors-ue-3', 'autres']),
    'zee': CardGroup('grp-zee', layers: ['zee']),
    'fleuves': CardGroup('grp-fleuves', layers: ['fleuves', 'grands-fleuves']),
    'eroutes': CardGroup('grp-eroutes', layers: ['eroutes']),
    'voisins': CardGroup('grp-voisins',
        layers: ['routes-voisins-brutes']),
    'lgv': CardGroup('grp-lgv',
        layers: ['lgv'], points: ['lgv-stations']),
    'capitales': CardGroup('grp-capitales', points: ['capitales']),
    'villes': CardGroup('grp-villes', points: ['villes']),
    'panonceaux': CardGroup('grp-panonceaux',
        points: ['refs-aut', 'refs-rn', 'refs-rd', 'refs-er']),
  },
  'monde': {
    'nuit': CardGroup('grp-nuit'),
    'soleil': CardGroup('grp-soleil'),
    'grille': CardGroup('grp-grille'),
    'fuseaux': CardGroup('grp-fuseaux'),
    'equal-earth': CardGroup('grp-equal-earth'),
    'frontieres': CardGroup('grp-frontieres', layers: ['frontieres']),
    'villes': CardGroup('grp-villes', points: ['villes']),
    'horloges': CardGroup('grp-horloges'),
  },
};

/* the styles of the world map, those of WM_STYLES of the web; the
   labels are keys of the glossary */
const styleLabels = <String, String>{
  'ocean': 'style-ocean',
  'nuit': 'style-nuit',
  'encre': 'style-encre',
  'croquis': 'style-croquis',
};

/* the centers of the world map, those of the web dialog; a small class
   rather than a double-keyed map: Dart refuses doubles as keys of a
   const map; the titles are keys of the glossary */
class WorldCenter {
  final double value;
  final String title;
  const WorldCenter(this.value, this.title);
}

const worldCenters = <WorldCenter>[
  WorldCenter(0.0, 'centre-greenwich'),
  WorldCenter(-90.0, 'centre-ameriques'),
  WorldCenter(150.0, 'centre-oceanie'),
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
  /* the clocks stay off until they are lit: they take room under the
     time slider, the web opens its table on demand */
  if (map == 'monde' && !p.containsKey('visibilite-monde-horloges')) {
    m['horloges'] = false;
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

/* The Equal Earth projection follows the group switch of the dialog
   ( visibilite-monde-equal-earth ), like the sun, the graticule and
   the time zones: one single preference key per option. */

/* the choices of the contested borders menu: one key per conflict,
   an empty value stays neutral, everything persists as JSON */
Future<Map<String, String>> readDisputed() async {
  final p = await SharedPreferences.getInstance();
  final s = p.getString('conflits-monde');
  if (s == null || s.isEmpty) return <String, String>{};
  try {
    final decoded = jsonDecode(s);
    if (decoded is Map<String, dynamic>) {
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    }
  } catch (_) {}
  return <String, String>{};
}

Future<void> writeDisputed(Map<String, String> conflicts) async {
  final p = await SharedPreferences.getInstance();
  await p.setString('conflits-monde', jsonEncode(conflicts));
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
    double worldCenter,
    Map<String, String> conflicts, {
    void Function(String group, bool value)? onChanged,
    void Function(String style)? onStyleChanged,
    void Function(double center)? onCenterChanged,
    void Function(Map<String, String> conflicts)? onConflictsChanged,
    void Function()? onPickCities,
  }) async {
  var style = worldStyle;
  var center = worldCenter;
  var disputed = conflicts;
  await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
          builder: (context, setSheet) => SafeArea(
                child: ListView(shrinkWrap: true, children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Text(translate('reglages-carte'),
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  for (final e
                      in (cardGroups[map] ?? const <String, CardGroup>{})
                          .entries)
                    SwitchListTile(
                      title: Text(translate(e.value.title)),
                      value: groups[e.key] ?? true,
                      onChanged: (value) {
                        setSheet(() {});
                        onChanged?.call(e.key, value);
                      },
                    ),
                  if (map == 'monde') ...[
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                      child: Text(translate('dlg-contestees')),
                    ),
                    ListTile(
                      leading: const Icon(Icons.public),
                      title: Text(translate('dlg-contestees')),
                      subtitle: Text(translate('dlg-choisir-vues')),
                      trailing: disputed.values.any((v) => v.isNotEmpty)
                          ? Badge(
                              label:
                                  Text('${disputed.values.where((v) => v.isNotEmpty).length}'),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: () async {
                        await disputedBordersDialog(context, disputed,
                            (updated) {
                          setSheet(() => disputed = updated);
                          onConflictsChanged?.call(updated);
                        });
                      },
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                      child: Text(translate('dlg-apparence')),
                    ),
                    for (final s in styleLabels.keys)
                      RadioListTile<String>(
                        title: Text(translate(styleLabels[s] ?? s)),
                        value: s,
                        groupValue: style,
                        onChanged: (value) {
                          if (value == null) return;
                          setSheet(() => style = value);
                          onStyleChanged?.call(value);
                        },
                      ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                      child: Text(translate('dlg-centrage')),
                    ),
                    for (final c in worldCenters)
                      RadioListTile<double>(
                        title: Text(translate(c.title)),
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
                      title: Text(translate('dlg-villes-marquees')),
                      subtitle: Text(translate('dlg-choisir-villes')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: onPickCities,
                    ),
                  ],
                  const SizedBox(height: 12),
                ]),
              )));
}

/* the choices of the eight conflicts, like the unfolding menu of the
   web: a neutral radio ( dotted or ordinary border ) and one radio
   per view; an empty value stays neutral and no side is taken */
Future<void> disputedBordersDialog(
    BuildContext context,
    Map<String, String> conflicts,
    void Function(Map<String, String> updated) onChange) async {
  /* the neutral label and the value of each radio: the de facto
     situations read as such, the others as neutral; the labels are
     keys of the glossary */
  const neutralLabels = <String, String>{
    'chypre': 'neutre-chypre',
    'golan': 'neutre-golan',
  };
  const views = <String, List<List<String>>>{
    'crimee': [
      ['ua', 'vue-ukrainienne'],
      ['ru', 'vue-russe'],
    ],
    'kashmir': [
      ['in', 'vue-indienne'],
      ['pk', 'vue-pakistanaise'],
    ],
    'taiwan': [
      ['cn', 'vue-chinoise'],
    ],
    'wsahara': [
      ['ma', 'vue-marocaine'],
    ],
    'kosovo': [
      ['rs', 'vue-serbe'],
    ],
    'chypre': [
      ['unie', 'ile-unie'],
    ],
    'golan': [
      ['syrien', 'rattache-syrie'],
    ],
    'essequibo': [
      ['ve', 'vue-venezuelienne'],
    ],
  };
  var current = conflicts;
  await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
          builder: (context, setSheet) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Text(translate('dlg-contestees'),
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  Flexible(
                      child: ListView(shrinkWrap: true, children: [
                    for (final e in disputedGroups.entries) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                        child: Text(translate('conflit-${e.key}'),
                            style:
                                Theme.of(context).textTheme.titleSmall),
                      ),
                      RadioListTile<String>(
                        dense: true,
                        title: Text(translate(neutralLabels[e.key] ?? 'neutre')),
                        value: '',
                        groupValue: current[e.key] ?? '',
                        onChanged: (value) {
                          setSheet(() {});
                          final updated = {...current};
                          updated[e.key] = value ?? '';
                          current = updated;
                          onChange(updated);
                        },
                      ),
                      for (final v in views[e.key] ?? const <List<String>>[])
                        RadioListTile<String>(
                          dense: true,
                          title: Text(translate(v[1])),
                          value: v[0],
                          groupValue: current[e.key] ?? '',
                          onChanged: (value) {
                            setSheet(() {});
                            final updated = {...current};
                            updated[e.key] = value ?? '';
                            current = updated;
                            onChange(updated);
                          },
                        ),
                    ],
                  ])),
                ]),
              )));
}

/* the box of the marked cities of the world: one checkbox per city of
   the database, show all and none at once; every change persists at
   once */Future<void> worldCitiesDialog(BuildContext context, List<String> names,
    Set<String> hidden, void Function(Set<String> updated) onChange) async {
  await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
          builder: (context, setSheet) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Text(translate('dlg-villes-marquees'),
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                        '${names.length - hidden.length} ${translate('dlg-sur')} ${names.length}'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(children: [
                      TextButton(
                          onPressed: () {
                            setSheet(() {});
                            onChange(<String>{});
                          },
                          child: Text(translate('dlg-tout-afficher'))),
                      TextButton(
                          onPressed: () {
                            setSheet(() {});
                            onChange(names.toSet());
                          },
                          child: Text(translate('dlg-aucune'))),
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
