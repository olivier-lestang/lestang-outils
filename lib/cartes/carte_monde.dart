/* La carte du monde : reglages, zone de nuit et infobulle, dans un
   fichier a part, distinct de la carte de l Union europeenne et des
   DROM-COM. Le rendu reprend les couleurs du web ( js/monde ) en deux
   palettes clair / sombre ; la zone de nuit est calculee sur place
   ( projection Equal Earth du web ).
   SPDX-License-Identifier : MIT. */
import 'dart:ui' show Canvas;

import 'package:flutter/material.dart';

import '../bdd.dart' as bdd;
import 'projection_monde.dart';
import 'styles_cartes.dart';

/* les couches et points de la carte du monde dans la base */
const couchesMonde = <String>['frontieres'];
const pointsMonde = <String>['villes'];

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

/* la zone de nuit : la courbe terminatrice puis la fermeture par le
   pole en nuit, remplie d un voile fonce ; c est la nuit qui est
   teintee, le jour reste clair */
void dessineZoneNuit(
    Canvas canvas, Offset Function(double, double) versPlan, DateTime heure) {
  final soleil = pointSolaire(heure.toUtc());
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

/* l infobulle du monde : la ville la plus proche du doigt, sinon la
   longitude et la latitude inversees de la projection ; px et py sont
   les coordonnees du plan touche, limite le rayon de la ville en unites
   du plan */
String infobulleMonde(
    double px, double py, List<bdd.PointNomme> villes, double limite) {
  final inv = eeInv(px / ratioEe, py);
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
      meilleure < limite) {
    return proche.nom + (proche.info.isEmpty ? '' : ' · ${proche.info}');
  }
  return '${inv[1].toStringAsFixed(1)}°, ${inv[0].toStringAsFixed(1)}°';
}
