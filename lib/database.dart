/* Access to the embedded SQLite database: the database travels in the
   assets, the first opening copies it to the application folder.
   SPDX-License-Identifier: MIT. */
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'conj/engines.dart';
import 'workers.dart';

Database? _db;
final Map<String, ConjugTables> _conjCache = {};

Future<String> databasePath() async {
  final dir = await getApplicationSupportDirectory();
  return p.join(dir.path, 'lestang_outils.db');
}

/// The version of the embedded data, to keep in sync with the meta value
/// written by tools/build_db.py.
const databaseVersion = '1.5.65';

/// Opens the database: the first time, the asset is copied to disk.
/// The installed copy is refreshed from the asset whenever its version
/// ( meta table ) differs: without this, the database of the first
/// launch would stay forever, even after an application update.
Future<Database> openDatabase() async {
  if (_db != null) return _db!;
  final path = await databasePath();
  final f = File(path);
  if (f.existsSync()) {
    var upToDate = false;
    try {
      final probe = sqlite3.open(path, mode: OpenMode.readOnly);
      final rs =
          probe.select('SELECT valeur FROM meta WHERE cle=?', ['version']);
      upToDate =
          rs.isNotEmpty && (rs.first['valeur'] as String) == databaseVersion;
      probe.dispose();
    } catch (_) {
      upToDate = false;
    }
    if (!upToDate) f.deleteSync();
  }
  if (!f.existsSync()) {
    final bytes = await rootBundle.load('assets/lestang_outils.db');
    await f.parent.create(recursive: true);
    await f.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
  }
  _db = sqlite3.open(path, mode: OpenMode.readOnly);
  return _db!;
}

/* ---------------- conjugation ---------------- */

/// Loads the three raw strings of a language then decodes them once.
Future<ConjugTables> conjugationTables(String language) async {
  final cache = _conjCache[language];
  if (cache != null) return cache;
  final db = await openDatabase();
  String raw(String what) {
    final rs = db.select('SELECT valeur FROM conj_raw WHERE langue=? AND quoi=?',
        [language, what]);
    return rs.isEmpty ? '' : rs.first['valeur'] as String;
  }
  final tpl = raw('tpl');
  final verbs = raw('verbs');
  final defs = raw('defs');
  final vsrc = raw('vsrc');
  /* the four raw strings parse in a background isolate: the tables of
     a language build in one pass and the interface never freezes,
     the status bar counts the worker while it runs */
  AppWorkers.spawned++;
  try {
    final set = await _parseConjugation(language, tpl, verbs, defs, vsrc);
    _conjCache[language] = set;
    return set;
  } finally {
    AppWorkers.spawned--;
  }
}

/* the parsing runs in its own function: a closure sent to an isolate
   carries its whole context, the one of conjugationTables holds the
   sqlite database and its native finalizer, which never crosses the
   boundary of an isolate; this scope only knows the five strings, so
   the message stays clean and the isolate accepts it */
Future<ConjugTables> _parseConjugation(String language, String tpl,
    String verbs, String defs, String vsrc) {
  return Isolate.run(
      () => ConjugTables.from(language, tpl, verbs, defs, vsrc));
}

/* ---------------- geography ---------------- */

/// A geometry feature: label + Float32 points (x, y, x, y...).
class GeoFeature {
  final String label;
  final Float32List points;
  GeoFeature(this.label, this.points);
}

/// A complete layer of a map.
class GeoLayer {
  final List<GeoFeature> features;
  GeoLayer(this.features);
}

/// A named point: name, position in the plane, free-form info.
class NamedPoint {
  final String name;
  final double x;
  final double y;
  final String info;
  NamedPoint(this.name, this.x, this.y, this.info);
}

/* a raw geometry row, ready to cross the boundary of the isolate */
class _RawGeo {
  final String label;
  final int n;
  final Uint8List geom;
  const _RawGeo(this.label, this.n, this.geom);
}

/* decodes one blob: the header ( n ) then n pairs of float32; an
   aligned copy avoids reading from byte 0 of the whole buffer, which
   used to shift every coordinate and leave the maps empty */
GeoFeature _decodeGeo(_RawGeo r) {
  final chunk = Uint8List.sublistView(r.geom, 4, 4 + r.n * 8);
  final copy = Uint8List.fromList(chunk);
  return GeoFeature(r.label, Float32List.view(copy.buffer, 0, r.n * 2));
}

Future<GeoLayer> layer(String map, String layerName) async {
  final db = await openDatabase();
  final rs = db.select(
      'SELECT etiquette, n, geom FROM geo WHERE carte=? AND couche=?',
      [map, layerName]);
  if (rs.isEmpty) return GeoLayer(const []);
  final raw = [
    for (final r in rs)
      _RawGeo(r['etiquette'] as String, r['n'] as int, r['geom'] as Uint8List)
  ];
  /* a heavy layer ( the world borders of the 1:10M precision ) decodes
     in a background isolate: the UI thread never freezes, the status
     bar counts the worker while it runs */
  AppWorkers.spawned++;
  try {
    final features = await Isolate.run(() => raw.map(_decodeGeo).toList());
    return GeoLayer(features);
  } finally {
    AppWorkers.spawned--;
  }
}

Future<List<NamedPoint>> points(String map, String layerName) async {
  final db = await openDatabase();
  final rs = db.select(
      'SELECT nom, x, y, info FROM points WHERE carte=? AND couche=? '
      'ORDER BY nom',
      [map, layerName]);
  return rs
      .map((r) => NamedPoint(r['nom'] as String, (r['x'] as num).toDouble(),
          (r['y'] as num).toDouble(), (r['info'] ?? '') as String))
      .toList();
}

/// A value of the meta table, or null.
Future<String?> metaValue(String key) async {
  final db = await openDatabase();
  final rs = db.select('SELECT valeur FROM meta WHERE cle=?', [key]);
  return rs.isEmpty ? null : rs.first['valeur'] as String;
}