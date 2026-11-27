/* Les cartes geographiques : France, Union europeenne, Monde.
   Les geometries viennent de la base SQLite, le rendu reprend les couleurs
   du web ( js/france, js/union, js/monde ) en deux palettes clair / sombre.
   L Union colore chaque Etat membre ; la carte du monde dessine la
   projection Equal Earth du web et la zone de nuit calculee sur place.
   SPDX-License-Identifier : MIT. */
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector4;

import '../bdd.dart' as bdd;
import 'departements.dart';
import 'palette_union.dart';
import 'projection_monde.dart';

/* ratio du plan Equal Earth : 2.0546 pour 1 */
const double ratioEe = 2.0546;

/* ---------------- styles par couche ---------------- */

class StyleTrait {
  final Color couleur;
  final double largeur;
  final Color? remplissage;
  final List<double>? tirets;
  final bool ferme; // couche de polygones : la fermeture se trace
  const StyleTrait(this.couleur, this.largeur,
      {this.remplissage, this.tirets, this.ferme = false});
}

class StyleFleche {
  final Color couleur;
  final double rayon;
  final double? rayonMin; // visible au-dela de ce zoom (echelle)
  const StyleFleche(this.couleur, this.rayon, {this.rayonMin});
}

class ReglagesCarte {
  final Map<String, StyleTrait> couches;
  final Map<String, StyleFleche> points;
  final Map<String, int> labelsMinZoom; // etiquettes visibles au-dela du zoom
  final Rect bornes; // cadrage initial, en unites du plan
  const ReglagesCarte(
      this.couches, this.points, this.labelsMinZoom, this.bornes);
}

/* France metropole : x = lon * cos(46.245), y = lat */
ReglagesCarte reglagesFrance(bool clair) => ReglagesCarte(
      {
        'departements': StyleTrait(
            clair ? const Color(0x33000000) : const Color(0x33ffffff), 0.6,
            remplissage:
                clair ? const Color(0x14669933) : const Color(0x14669933),
            ferme: true),
        'contour': StyleTrait(
            clair ? const Color(0xff495057) : const Color(0xffced4da), 1.2,
            ferme: true),
        'autoroutes': StyleTrait(
            clair ? const Color(0xffc92a2a) : const Color(0xffff8787), 1.0),
        'nationales': StyleTrait(
            clair ? const Color(0xffe8590c) : const Color(0xffff922b), 0.8),
        'departementales': StyleTrait(
            clair ? const Color(0x88a8891c) : const Color(0x88d4b83a), 0.5),
        'fleuves': StyleTrait(
            clair ? const Color(0xff1971c2) : const Color(0xff74c0fc), 1.0),
        'zee': StyleTrait(const Color(0x00000000), 0,
            remplissage:
                clair ? const Color(0x221c7ed6) : const Color(0x22191970)),
        'lgv': StyleTrait(
            clair ? const Color(0xff6741d9) : const Color(0xff9775fa), 1.6,
            tirets: [4.0, 2.5]),
        'paris': StyleTrait(
            clair ? const Color(0xff862e9c) : const Color(0xffe64980), 0.8),
        'villes-transports': StyleTrait(
            clair ? const Color(0xff0b7285) : const Color(0xff3bc9db), 0.6),
      },
      {
        'grandes-villes': StyleFleche(
            clair ? const Color(0xff212529) : const Color(0xfff1f3f5), 2.2,
            rayonMin: -1),
        'chefs-lieux': StyleFleche(
            clair ? const Color(0xff495057) : const Color(0xffadb5bd), 1.6,
            rayonMin: 1.2),
        'villes': StyleFleche(
            clair ? const Color(0xff495057) : const Color(0xffadb5bd), 1.2,
            rayonMin: 2.5),
        'stations': StyleFleche(
            clair ? const Color(0xffc2255c) : const Color(0xffff74b6), 0.9,
            rayonMin: 6.0),
        'paris-stations': StyleFleche(
            clair ? const Color(0xffc2255c) : const Color(0xffff74b6), 0.9,
            rayonMin: 26.0),
        'lgv-stations': StyleFleche(
            clair ? const Color(0xff5f3dc4) : const Color(0xffb197fc), 1.3,
            rayonMin: 5.0),
      },
      {
        'grandes-villes': -1,
        'chefs-lieux': 3,
        'villes': 7,
        'lgv-stations': 5,
        'paris-stations': 30,
      },
      Rect.fromLTRB((2.30 - 6.0) * 0.6918, 51.85, (2.30 + 6.0) * 0.6918, 41.35),
    );

/* cadrages des outre-mer : longitude ouest, latitude nord, largeur, hauteur */
const double _c46 = 0.6918;
const cadragesOutreMer = <String, Rect>{
  'Guadeloupe': Rect.fromLTRB(
      (61.51 - 0.7) * _c46, 16.18 + 0.7, (61.51 + 0.7) * _c46, 16.18 - 0.7),
  'Martinique': Rect.fromLTRB(
      (61.02 - 0.5) * _c46, 14.64 + 0.5, (61.02 + 0.5) * _c46, 14.64 - 0.5),
  'Guyane': Rect.fromLTRB(
      (53.2 - 2.5) * _c46, 4.0 + 2.5, (53.2 + 2.5) * _c46, 4.0 - 2.5),
  'La Réunion': Rect.fromLTRB(
      (55.5 - 0.8) * _c46, -21.05 + 0.8, (55.5 + 0.8) * _c46, -21.05 - 0.8),
  'Mayotte': Rect.fromLTRB(
      (45.16 - 0.5) * _c46, -12.78 + 0.5, (45.16 + 0.5) * _c46, -12.78 - 0.5),
};

/* Union europeenne : memes unites que la France */
ReglagesCarte reglagesUnion(bool clair) => ReglagesCarte(
      {
        'membres': StyleTrait(
            clair ? const Color(0xff495057) : const Color(0xffadb5bd), 0.5,
            ferme: true),
        'autres': StyleTrait(
            clair ? const Color(0xff495057) : const Color(0xffadb5bd), 0.5,
            remplissage:
                clair ? const Color(0x336b705c) : const Color(0x3394a396),
            ferme: true),
        'hors-ue': StyleTrait(
            clair ? const Color(0xff868e96) : const Color(0xff6c757d), 0.4,
            remplissage:
                clair ? const Color(0x14adb5bd) : const Color(0x14349db4),
            ferme: true),
        'hors-ue-2': StyleTrait(
            clair ? const Color(0xff868e96) : const Color(0xff6c757d), 0.4,
            remplissage:
                clair ? const Color(0x14adb5bd) : const Color(0x14349db4),
            ferme: true),
        'hors-ue-3': StyleTrait(
            clair ? const Color(0xff868e96) : const Color(0xff6c757d), 0.4,
            remplissage:
                clair ? const Color(0x14adb5bd) : const Color(0x14349db4),
            ferme: true),
        'zee': StyleTrait(const Color(0x00000000), 0,
            remplissage:
                clair ? const Color(0x221c7ed6) : const Color(0x22191970)),
        'fleuves': StyleTrait(
            clair ? const Color(0xff1971c2) : const Color(0xff74c0fc), 0.7),
        'grands-fleuves': StyleTrait(
            clair ? const Color(0xff1971c2) : const Color(0xff74c0fc), 1.0),
        'eroutes': StyleTrait(
            clair ? const Color(0xff2f9e44) : const Color(0xff69db7c), 1.4,
            remplissage: null),
        'routes-voisins-brutes': StyleTrait(
            clair ? const Color(0x88a8891c) : const Color(0x88d4b83a), 0.5),
        'lgv': StyleTrait(
            clair ? const Color(0xff6741d9) : const Color(0xff9775fa), 1.4,
            tirets: [4.0, 2.5]),
      },
      {
        'capitales': StyleFleche(
            clair ? const Color(0xffc92a2a) : const Color(0xffff8787), 2.0,
            rayonMin: -1),
        'villes': StyleFleche(
            clair ? const Color(0xff212529) : const Color(0xfff1f3f5), 1.2,
            rayonMin: 3.0),
        'lgv-stations': StyleFleche(
            clair ? const Color(0xff5f3dc4) : const Color(0xffb197fc), 1.3,
            rayonMin: 5.0),
      },
      {
        'capitales': -1,
        'villes': 6,
        'lgv-stations': 5,
      },
      Rect.fromLTRB((15.0 - 23.0) * 0.6918, 67.0, (15.0 + 23.0) * 0.6918, 35.0),
    );

/* Monde : lon et lat bruts, projetes en Equal Earth au dessin */
ReglagesCarte reglagesMonde(bool clair) => ReglagesCarte(
      {
        'frontieres': StyleTrait(
            clair ? const Color(0xff495057) : const Color(0xffadb5bd), 0.4,
            remplissage:
                clair ? const Color(0x146b705c) : const Color(0x142f9e44),
            ferme: true),
      },
      {
        'villes': StyleFleche(
            clair ? const Color(0xffc92a2a) : const Color(0xffff8787), 1.8,
            rayonMin: -1),
      },
      {
        'villes': -1,
      },
      const Rect.fromLTRB(-ratioEe, 1, ratioEe, -1),
    );

/* ---------------- le peintre ---------------- */

class PeintreCarte extends CustomPainter {
  final String carte;
  final Map<String, bdd.CoucheGeo> couches;
  final Map<String, List<bdd.PointNomme>> points;
  final ReglagesCarte reglages;
  final TransformationController transformation;
  final Color fondTexte;
  final DateTime heureMonde; // heure de la zone de nuit
  final bool clair;

  PeintreCarte(this.carte, this.couches, this.points, this.reglages,
      this.transformation, this.fondTexte, this.heureMonde, this.clair)
      : super(repaint: transformation);

  @override
  bool shouldRepaint(PeintreCarte old) =>
      old.carte != carte || old.heureMonde != heureMonde || old.clair != clair;

  /* longitude et latitude brutes vers le plan du monde ( Equal Earth ) */
  Offset projetee(double lon, double lat) {
    final p = ee(lat, lon);
    return Offset(p.dx * ratioEe, p.dy);
  }

  @override
  void paint(Canvas canvas, Size taille) {
    final b = reglages.bornes;
    final echelle = math.min(taille.width / b.width, taille.height / -b.height);
    final dx = (taille.width - b.width * echelle) / 2 - b.left * echelle;
    final dy = (taille.height + b.height * echelle) / 2 + b.top * echelle;
    /* le plan y monte, l ecran y descend */
    Offset versPlan(double x, double y) =>
        Offset(dx + x * echelle, dy - y * echelle);
    final m = transformation.value;
    final zoom = m.getMaxScaleOnAxis();

    /* contours remplis d abord */
    for (final e in reglages.couches.entries) {
      final couche = couches[e.key];
      if (couche == null) continue;
      final st = e.value;
      if (e.key == 'membres') {
        /* une teinte pastel par Etat membre, comme le web */
        for (final tr in couche.troncons) {
          final p = Path();
          _ajouterTronconEcran(p, tr, versPlan, fermer: true);
          canvas.drawPath(
              p, Paint()..color = paletteUe[tr.etiquette] ?? teinteUeDefaut);
        }
        continue;
      }
      if (st.remplissage == null) continue;
      final p = Path();
      for (final tr in couche.troncons) {
        _ajouterTronconEcran(p, tr, versPlan, fermer: true);
      }
      final peinture = Paint()..color = st.remplissage!;
      canvas.drawPath(p, peinture);
    }
    /* traits par-dessus : l epaisseur et les tirets sont contre-cales
       par le zoom, ils gardent une taille constante a l ecran */
    for (final e in reglages.couches.entries) {
      final couche = couches[e.key];
      if (couche == null) continue;
      final st = e.value;
      if (st.couleur.alpha == 0 && st.largeur == 0) continue;
      final p = Path();
      for (final tr in couche.troncons) {
        _ajouterTronconEcran(p, tr, versPlan, fermer: st.ferme);
      }
      final peinture = Paint()
        ..style = PaintingStyle.stroke
        ..color = st.couleur
        ..strokeWidth = st.largeur / zoom
        ..isAntiAlias = true;
      if (st.tirets == null) {
        canvas.drawPath(p, peinture);
      } else {
        for (final morceau in p.computeMetrics()) {
          double avance = 0;
          final longue = morceau.length;
          final motif = st.tirets!;
          var k = 0;
          while (avance < longue) {
            final bout = motif[k % motif.length] / zoom;
            final fin = math.min(avance + bout, longue);
            canvas.drawPath(morceau.extractPath(avance, fin), peinture);
            avance = fin + motif[(k + 1) % motif.length] / zoom;
            k += 2;
          }
        }
      }
    }
    /* zone de nuit du monde */
    if (carte == 'monde') {
      final soleil = pointSolaire(heureMonde.toUtc());
      final polygone = polygoneNuit(soleil);
      final path = Path();
      var premier = true;
      for (final sommet in polygone) {
        final pos = versPlan(sommet.dx * ratioEe, sommet.dy);
        if (premier) {
          path.moveTo(pos.dx, pos.dy);
          premier = false;
        } else {
          path.lineTo(pos.dx, pos.dy);
        }
      }
      path.close();
      canvas.drawPath(path, Paint()..color = const Color(0x55000c33));
    }
    /* points et etiquettes : rayons et textes contre-cales, taille
       constante a l ecran quel que soit le zoom */
    final contreEchelle = 1.0 / zoom;
    for (final e in reglages.points.entries) {
      final liste = points[e.key];
      if (liste == null) continue;
      final st = e.value;
      final zoomMin = st.rayonMin ?? 0;
      if (zoom < zoomMin) continue;
      final peinture = Paint()..color = st.couleur;
      for (final pt in liste) {
        final pos = _versEcran(pt.x, pt.y, versPlan);
        if (pos.dx < -60 ||
            pos.dy < -60 ||
            pos.dx > taille.width + 60 ||
            pos.dy > taille.height + 60) {
          continue;
        }
        canvas.drawCircle(pos, st.rayon * contreEchelle, peinture);
      }
      final labelZoom = reglages.labelsMinZoom[e.key];
      if (labelZoom != null && zoom >= labelZoom) {
        for (final pt in liste) {
          _etiquette(canvas, pt.nom, _versEcran(pt.x, pt.y, versPlan),
              decal: (st.rayon + 2) * contreEchelle, echelle: contreEchelle);
        }
      }
    }
    /* panonceaux des routes de l Union aux forts zooms */
    if (carte == 'union' && zoom > 15) {
      final panonceaux = <String, List<Color>>{
        'refs-aut': [const Color(0xffd0141a), Colors.white],
        'refs-rn': [const Color(0xffd0141a), Colors.white],
        'refs-rd': [const Color(0xffe8c220), Colors.black],
        'refs-er': [const Color(0xff1a8f3c), Colors.white],
      };
      for (final e in panonceaux.entries) {
        final liste = points[e.key];
        if (liste == null) continue;
        for (final pt in liste) {
          _etiquetteFond(canvas, pt.nom, _versEcran(pt.x, pt.y, versPlan),
              fond: e.value[0],
              texte: e.value[1],
              echelle: contreEchelle);
        }
      }
    }
  }

  /* position ecran d un point de la base : monde projete, autres a plat */
  Offset _versEcran(
      double x, double y, Offset Function(double, double) versPlan) {
    if (carte != 'monde') return versPlan(x, y);
    final p = ee(y, x);
    return versPlan(p.dx * ratioEe, p.dy);
  }

  void _ajouterTronconEcran(
      Path p, bdd.Troncon tr, Offset Function(double, double) v,
      {bool fermer = false}) {
    final pts = tr.points;
    if (pts.isEmpty) return;
    var premier = true;
    for (var i = 0; i + 1 < pts.length; i += 2) {
      final pos = _versEcran(pts[i], pts[i + 1], v);
      if (premier) {
        p.moveTo(pos.dx, pos.dy);
        premier = false;
      } else {
        p.lineTo(pos.dx, pos.dy);
      }
    }
    /* la fermeture ne se trace que pour les couches de polygones :
       sur une polyligne ouverte ( fleuve, route ), close() dessinait
       une corde droite qui apparaissait en barre au zoom */
    if (fermer) p.close();
  }

  void _etiquette(Canvas canvas, String texte, Offset pos,
      {double decal = 3, double echelle = 1}) {
    final tp = TextPainter(
      text: TextSpan(
          text: texte,
          style: TextStyle(
              fontSize: 10 * echelle,
              color: fondTexte,
              backgroundColor:
                  clair ? const Color(0x66000000) : const Color(0x66ffffff))),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos + Offset(decal, -tp.height / 2));
  }

  void _etiquetteFond(Canvas canvas, String libelle, Offset pos,
      {required Color fond,
      Color texte = const Color(0xffffffff),
      double echelle = 1}) {
    final tp = TextPainter(
      text: TextSpan(
          text: libelle,
          style: TextStyle(
              fontSize: 9 * echelle,
              fontWeight: FontWeight.w700,
              color: texte,
              letterSpacing: 0.5 * echelle)),
      textDirection: TextDirection.ltr,
    )..layout();
    final rect = Rect.fromCenter(
        center: pos,
        width: tp.width + 8 * echelle,
        height: tp.height + 4 * echelle);
    final radius = Radius.circular(rect.height / 2);
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, radius), Paint()..color = fond);
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, radius),
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.white
          ..strokeWidth = echelle);
    tp.paint(canvas,
        rect.topLeft + Offset(4 * echelle, 2 * echelle));
  }
}

/* ---------------- l ecran d une carte ---------------- */

class EcranCarte extends StatefulWidget {
  final String carte;
  const EcranCarte(this.carte, {super.key});

  @override
  State<EcranCarte> createState() => _EcranCarteState();
}

class _EcranCarteState extends State<EcranCarte> {
  final _transformation = TransformationController();
  Map<String, bdd.CoucheGeo>? _couches;
  Map<String, List<bdd.PointNomme>>? _points;
  DateTime _heure = DateTime.now();
  String? _cadrage; // cadrage outre-mer choisi

  static const _nomsCouches = <String, List<String>>{
    'france': [
      'departements',
      'contour',
      'zee',
      'fleuves',
      'departementales',
      'nationales',
      'autoroutes',
      'lgv',
      'paris',
      'villes-transports'
    ],
    'union': [
      'hors-ue',
      'hors-ue-2',
      'hors-ue-3',
      'autres',
      'membres',
      'zee',
      'fleuves',
      'grands-fleuves',
      'routes-voisins-brutes',
      'eroutes',
      'lgv'
    ],
    'monde': ['frontieres'],
  };
  static const _nomsPoints = <String, List<String>>{
    'france': [
      'grandes-villes',
      'chefs-lieux',
      'villes',
      'lgv-stations',
      'stations',
      'paris-stations'
    ],
    'union': [
      'capitales',
      'villes',
      'lgv-stations',
      'refs-aut',
      'refs-rn',
      'refs-rd',
      'refs-er'
    ],
    'monde': ['villes'],
  };

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final couches = <String, bdd.CoucheGeo>{};
    for (final c in _nomsCouches[widget.carte] ?? const <String>[]) {
      couches[c] = await bdd.couche(widget.carte, c);
    }
    final pts = <String, List<bdd.PointNomme>>{};
    for (final c in _nomsPoints[widget.carte] ?? const <String>[]) {
      pts[c] = await bdd.points(widget.carte, c);
    }
    if (mounted) {
      setState(() {
        _couches = couches;
        _points = pts;
      });
    }
  }

  @override
  void dispose() {
    _transformation.dispose();
    super.dispose();
  }

  /* infobulle : la ville la plus proche, sinon le polygone sous le doigt */
  Future<void> _toucher(Offset local, Size taille, bool clair) async {
    final reglages = _reglages(clair);
    final b = reglages.bornes;
    final echelle = math.min(taille.width / b.width, taille.height / -b.height);
    final dx = (taille.width - b.width * echelle) / 2 - b.left * echelle;
    final dy = (taille.height + b.height * echelle) / 2 + b.top * echelle;
    final inverse = (_transformation.value.clone()..invert())
        .transform(Vector4(local.dx, local.dy, 0, 1));
    /* coordonnees du plan touchees */
    final px = (inverse.x - dx) / echelle;
    final py = (dy - inverse.y) / echelle;
    String? texte;
    if (widget.carte == 'monde') {
      final inv = eeInv(px / ratioEe, py);
      final villes = _points?['villes'] ?? const <bdd.PointNomme>[];
      bdd.PointNomme? proche;
      var meilleure = 1e9;
      for (final v in villes) {
        final p = ee(v.y, v.x);
        final dd = (p.dx * ratioEe - px) * (p.dx * ratioEe - px) +
            (p.dy - py) * (p.dy - py);
        if (dd < meilleure) {
          meilleure = dd;
          proche = v;
        }
      }
      if (proche != null &&
          proche.nom.isNotEmpty &&
          meilleure * echelle * echelle < 20 * 20) {
        texte = proche.nom + (proche.info.isEmpty ? '' : ' · ${proche.info}');
      } else {
        texte = '${inv[1].toStringAsFixed(1)}°, ${inv[0].toStringAsFixed(1)}°';
      }
    } else {
      /* ville la plus proche a moins de 14 px */
      for (final e in reglages.points.entries) {
        final liste = _points?[e.key];
        if (liste == null) continue;
        for (final v in liste) {
          final dd = (v.x - px) * (v.x - px) + (v.y - py) * (v.y - py);
          if (dd * echelle * echelle < 14 * 14) {
            texte = v.nom + (v.info.isEmpty ? '' : ' · ${v.info}');
            break;
          }
        }
        if (texte != null) break;
      }
      if (texte == null) {
        /* polygone du departement ou du pays sous le doigt */
        final couche =
            _couches?[widget.carte == 'france' ? 'departements' : 'membres'];
        if (couche != null) {
          for (final tr in couche.troncons) {
            if (!_dansPolygone(px, py, tr.points)) continue;
            if (widget.carte == 'france') {
              final f = departements[tr.etiquette];
              texte = f == null
                  ? tr.etiquette
                  : '${tr.etiquette} · ${f[0]}'
                      ' (${nomsRegions[f[1]] ?? f[1]})';
            } else {
              texte = '${tr.etiquette} · ${nomsPaysUe[tr.etiquette] ?? ''}';
            }
            break;
          }
        }
      }
    }
    if (!mounted) return;
    if (texte == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          duration: const Duration(seconds: 3),
          content: Text(texte, style: const TextStyle(fontSize: 13))));
  }

  /* point dans un polygone : lancer classique */
  bool _dansPolygone(double px, double py, Float32List pts) {
    var dedans = false;
    var j = 0;
    for (var i = 0; i + 1 < pts.length; i += 2) {
      final xi = pts[i], yi = pts[i + 1];
      final xj = pts[j], yj = pts[j + 1];
      if (((yi > py) != (yj > py)) &&
          (px < (xj - xi) * (py - yi) / (yj - yi) + xi)) {
        dedans = !dedans;
      }
      j = i;
    }
    return dedans;
  }

  ReglagesCarte _reglages(bool clair) {
    final r = widget.carte == 'france'
        ? reglagesFrance(clair)
        : widget.carte == 'union'
            ? reglagesUnion(clair)
            : reglagesMonde(clair);
    if (widget.carte == 'france' &&
        _cadrage != null &&
        cadragesOutreMer.containsKey(_cadrage)) {
      final c = cadragesOutreMer[_cadrage]!;
      return ReglagesCarte(r.couches, r.points, r.labelsMinZoom, c);
    }
    return r;
  }

  @override
  Widget build(BuildContext context) {
    if (_couches == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final clair = Theme.of(context).brightness == Brightness.light;
    final reglages = _reglages(clair);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (widget.carte == 'france')
        Wrap(spacing: 6, runSpacing: 4, children: [
          ChoiceChip(
            label: const Text('Métropole'),
            selected: _cadrage == null,
            onSelected: (_) => setState(() {
              _cadrage = null;
              _transformation.value = Matrix4.identity();
            }),
          ),
          for (final nom in cadragesOutreMer.keys)
            ChoiceChip(
              label: Text(nom),
              selected: _cadrage == nom,
              onSelected: (_) => setState(() {
                _cadrage = nom;
                _transformation.value = Matrix4.identity();
              }),
            ),
        ]),
      if (widget.carte == 'france') const SizedBox(height: 8),
      if (widget.carte == 'monde') ...[
        Row(children: [
          Expanded(
            child: Slider(
              value:
                  (_heure.hour * 2 + (_heure.minute >= 30 ? 1 : 0)).toDouble(),
              min: 0,
              max: 47,
              divisions: 48,
              label:
                  '${_heure.hour.toString().padLeft(2, '0')}:${_heure.minute.toString().padLeft(2, '0')}',
              onChanged: (double v) {
                final base = DateTime(_heure.year, _heure.month, _heure.day);
                setState(() =>
                    _heure = base.add(Duration(minutes: (v * 30).round())));
              },
            ),
          ),
          Text(_heure.toString().substring(11, 16)),
          IconButton(
            tooltip: 'Maintenant',
            icon: const Icon(Icons.restore),
            onPressed: () => setState(() => _heure = DateTime.now()),
          ),
        ]),
      ],
      Expanded(
        child: LayoutBuilder(builder: (context, contraintes) {
          final h =
              contraintes.maxWidth / (widget.carte == 'monde' ? ratioEe : 1.6);
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: InteractiveViewer(
              transformationController: _transformation,
              minScale: 0.8,
              maxScale: 200,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => _toucher(
                    d.localPosition, Size(contraintes.maxWidth, h), clair),
                child: CustomPaint(
                  size: Size(contraintes.maxWidth, h),
                  painter: PeintreCarte(
                      widget.carte,
                      _couches!,
                      _points!,
                      reglages,
                      _transformation,
                      clair ? const Color(0xff212529) : const Color(0xfff1f3f5),
                      _heure,
                      clair),
                ),
              ),
            ),
          );
        }),
      ),
    ]);
  }
}
