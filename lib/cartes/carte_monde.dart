/* La carte du monde : reglages, fond, zone de nuit et infobulle, dans un
   fichier a part, distinct de la carte de l Union europeenne et des
   DROM-COM. Les couleurs reprennent le style « ocean » du dernier HTML
   du web ( WM_STYLES.ocean de js/monde/carte-monde.js ) : fond degrade
   bleu profond, terres parchemin, voile de nuit bleu nuit. Le style
   ocean ne depend pas du theme clair ou sombre, comme sur le web.
   SPDX-License-Identifier : MIT. */
import 'dart:ui' show Canvas;

import 'package:flutter/material.dart';

import '../bdd.dart' as bdd;
import 'projection_monde.dart';
import 'styles_cartes.dart';

/* les couches et points de la carte du monde dans la base */
const couchesMonde = <String>['frontieres'];
const pointsMonde = <String>['villes'];

/* le style « ocean » du web, les memes valeurs dans les deux themes :
   fond degrade du bleu profond au bleu azur, terres couleur parchemin,
   frontieres gris bleute, voile de nuit bleu nuit ( WM_STYLES.ocean ) */
const _fondHaut = Color(0xff0b2f63); // bg[0]
const _fondBas = Color(0xff155399); // bg[1]
const _terre = Color(0xffe9e4d3); // land
const _frontiere = Color(0x8c5a6e87); // border rgba(90,110,135,0.55)
const _voileNuit = Color(0x73030816); // night rgba(3,8,22,0.45)

/* Monde : lon et lat bruts, projetes en Equal Earth au dessin */
ReglagesCarte reglagesMonde(bool clair) => ReglagesCarte(
      {
        'frontieres': StyleTrait(_frontiere, 0.4,
            remplissage: _terre, ferme: true),
      },
      {
        'villes': StyleFleche(const Color(0xffe03131), 1.8, rayonMin: -1),
      },
      {
        'villes': -1,
      },
      const Rect.fromLTRB(-ratioEe, 1, ratioEe, -1),
    );

/* le fond degrade du monde, comme le fond du canvas du web ( linear
   gradient vertical de bg[0] a bg[1] ), peint seulement dans le
   rectangle de la carte : le tour est trace par contourMonde, ainsi
   le globe se distingue du fond d ecran autour de lui */
void fondMonde(Canvas canvas, Rect rect) {
  final degrade = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_fondHaut, _fondBas])
      .createShader(rect);
  canvas.drawRect(rect, Paint()..shader = degrade);
}

/* le tour de la carte du monde : un trait gris bleute au bord du
   globe, arrondi comme les coins de la carte ; contreEchelle garde
   une epaisseur constante a l ecran quel que soit le zoom */
void contourMonde(Canvas canvas, Rect rect, double contreEchelle) {
  final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.75 * contreEchelle),
      Radius.circular(12 * contreEchelle));
  canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xff5a6e87)
        ..strokeWidth = 1.5 * contreEchelle
        ..isAntiAlias = true);
}

/* la zone de nuit : la courbe terminatrice puis la fermeture par le
   pole en nuit, remplie du voile bleu nuit du web ; c est la nuit qui
   est teintee, le jour reste clair */
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
  canvas.drawPath(path, Paint()..color = _voileNuit);
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
  if (proche != null && proche.nom.isNotEmpty && meilleure < limite) {
    return proche.nom + (proche.info.isEmpty ? '' : ' · ${proche.info}');
  }
  return '${inv[1].toStringAsFixed(1)}°, ${inv[0].toStringAsFixed(1)}°';
}