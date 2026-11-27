/* Acces a la base SQLite embarquee : la base voyage dans les assets, la
   premiere ouverture la copie vers le dossier de l application.
   SPDX-License-Identifier : MIT. */
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'conj/moteurs.dart';

Database? _bdd;
final Map<String, PlanchesConjug> _conjCache = {};

Future<String> cheminBdd() async {
  final dir = await getApplicationSupportDirectory();
  return p.join(dir.path, 'lestang_outils.db');
}

/// La version des donnees embarquees, a tenir a jour avec la valeur de
/// meta ecrite par outils/construire_bdd.py.
const versionBdd = '1.5.62';

/// Ouvre la base : la premiere fois, l asset est copie sur le disque.
/// La copie installee est reprise depuis l asset si sa version ( table
/// meta ) differe : sans cela, la base du premier lancement resterait
/// a jamais, meme apres mise a jour de l application.
Future<Database> bdd() async {
  if (_bdd != null) return _bdd!;
  final chemin = await cheminBdd();
  final f = File(chemin);
  if (f.existsSync()) {
    var aJour = false;
    try {
      final probe = sqlite3.open(chemin, mode: OpenMode.readOnly);
      final rs =
          probe.select('SELECT valeur FROM meta WHERE cle=?', ['version']);
      aJour = rs.isNotEmpty && (rs.first['valeur'] as String) == versionBdd;
      probe.dispose();
    } catch (_) {
      aJour = false;
    }
    if (!aJour) f.deleteSync();
  }
  if (!f.existsSync()) {
    final octets = await rootBundle.load('assets/lestang_outils.db');
    await f.parent.create(recursive: true);
    await f.writeAsBytes(octets.buffer.asUint8List(), flush: true);
  }
  _bdd = sqlite3.open(chemin, mode: OpenMode.readOnly);
  return _bdd!;
}

/* ---------------- conjugaison ---------------- */

/// Charge les trois chaines brutes d une langue puis les decode une fois.
Future<PlanchesConjug> tranchesConj(String langue) async {
  final cache = _conjCache[langue];
  if (cache != null) return cache;
  final db = await bdd();
  String raw(String quoi) {
    final rs = db.select('SELECT valeur FROM conj_raw WHERE langue=? AND quoi=?',
        [langue, quoi]);
    return rs.isEmpty ? '' : rs.first['valeur'] as String;
  }
  final jeu = PlanchesConjug.depuis(
      langue, raw('tpl'), raw('verbs'), raw('defs'), raw('vsrc'));
  _conjCache[langue] = jeu;
  return jeu;
}

/* ---------------- geographie ---------------- */

/// Un troncon de geometrie : etiquette + points Float32 (x, y, x, y...).
class Troncon {
  final String etiquette;
  final Float32List points;
  Troncon(this.etiquette, this.points);
}

/// Une couche complete d une carte.
class CoucheGeo {
  final List<Troncon> troncons;
  CoucheGeo(this.troncons);
}

/// Un point nomme : nom, position dans le plan, info libre.
class PointNomme {
  final String nom;
  final double x;
  final double y;
  final String info;
  PointNomme(this.nom, this.x, this.y, this.info);
}

Future<CoucheGeo> couche(String carte, String nomCouche) async {
  final db = await bdd();
  final rs = db.select(
      'SELECT etiquette, n, geom FROM geo WHERE carte=? AND couche=?',
      [carte, nomCouche]);
  final out = <Troncon>[];
  for (final r in rs) {
    final g = r['geom'] as Uint8List;
    final n = r['n'] as int;
    final f = Float32List.view(
        Uint8List.sublistView(g, 4, 4 + n * 8).buffer, 0, n * 2);
    out.add(Troncon(r['etiquette'] as String, f));
  }
  return CoucheGeo(out);
}

Future<List<PointNomme>> points(String carte, String nomCouche) async {
  final db = await bdd();
  final rs = db.select(
      'SELECT nom, x, y, info FROM points WHERE carte=? AND couche=? '
      'ORDER BY nom',
      [carte, nomCouche]);
  return rs
      .map((r) => PointNomme(r['nom'] as String, (r['x'] as num).toDouble(),
          (r['y'] as num).toDouble(), (r['info'] ?? '') as String))
      .toList();
}

/// Une valeur de la table meta, ou null.
Future<String?> meta(String cle) async {
  final db = await bdd();
  final rs = db.select('SELECT valeur FROM meta WHERE cle=?', [cle]);
  return rs.isEmpty ? null : rs.first['valeur'] as String;
}
