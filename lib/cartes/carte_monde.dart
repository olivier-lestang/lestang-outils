/* La carte du monde : reglages, fond, zone de nuit et infobulle, dans un
   fichier a part, distinct de la carte de l Union europeenne et des
   DROM-COM. Les couleurs reprennent les quatre styles du dernier HTML
   du web ( WM_STYLES de js/monde/carte-monde.js ) : ocean, nuit, encre
   et croquis, choisis dans la modale de reglages de la carte ; le
   style ne depend pas du theme clair ou sombre, comme sur le web.
   SPDX-License-Identifier : MIT. */
import 'dart:ui' show Canvas;

import 'package:flutter/material.dart';

import '../bdd.dart' as bdd;
import 'projection_monde.dart';
import 'styles_cartes.dart';

/* les couches et points de la carte du monde dans la base */
const couchesMonde = <String>['frontieres'];
const pointsMonde = <String>['villes'];

/* un style de carte du monde : fond degrade, terre, frontieres, voile
   de nuit et contour, les valeurs de WM_STYLES du web */
class StyleMonde {
  final Color fondHaut, fondBas, terre, frontiere, voileNuit, contour;
  const StyleMonde({
    required this.fondHaut,
    required this.fondBas,
    required this.terre,
    required this.frontiere,
    required this.voileNuit,
    required this.contour,
  });
}

/* les quatre styles du web, memes valeurs dans les deux themes :
   ocean ( defaut ), nuit, encre, croquis ( WM_STYLES ) */
const stylesMonde = <String, StyleMonde>{
  'ocean': StyleMonde(
      fondHaut: Color(0xff0b2f63),
      fondBas: Color(0xff155399),
      terre: Color(0xffe9e4d3),
      frontiere: Color(0x8c5a6e87),
      voileNuit: Color(0x73030816),
      contour: Color(0xff5a6e87)),
  'nuit': StyleMonde(
      fondHaut: Color(0xff090d1c),
      fondBas: Color(0xff141d38),
      terre: Color(0xff2c3452),
      frontiere: Color(0x809aa6c8),
      voileNuit: Color(0x8000000c),
      contour: Color(0xff9aa6c8)),
  'encre': StyleMonde(
      fondHaut: Color(0xfff3edde),
      fondBas: Color(0xffe6dcc3),
      terre: Color(0xff31405f),
      frontiere: Color(0x8c96b4e6),
      voileNuit: Color(0x38302858),
      contour: Color(0xff96b4e6)),
  'croquis': StyleMonde(
      fondHaut: Color(0xf2eee9da),
      fondBas: Color(0xf2e2dccb),
      terre: Color(0xfffaf6ec),
      frontiere: Color(0x801c2232),
      voileNuit: Color(0x290a0c16),
      contour: Color(0xff1c2232)),
};

/* Monde : lon et lat bruts, projetes en Equal Earth au dessin ; le
   style vient de la modale de reglages, ocean par defaut */
ReglagesCarte reglagesMonde(bool clair, [StyleMonde? style]) {
  final st = style ?? stylesMonde['ocean']!;
  return ReglagesCarte(
    {
      'frontieres': StyleTrait(st.frontiere, 0.4,
          remplissage: st.terre, ferme: true),
    },
    {
      'villes': StyleFleche(const Color(0xffe03131), 1.8, rayonMin: -1),
    },
    {
      'villes': -1,
    },
    const Rect.fromLTRB(-ratioEe, 1, ratioEe, -1),
  );
}

/* le fond degrade du monde, comme le fond du canvas du web ( linear
   gradient vertical de bg[0] a bg[1] du style choisi ), peint seulement
   dans le rectangle de la carte : le tour est trace par contourMonde,
   ainsi le globe se distingue du fond d ecran autour de lui */
void fondMonde(Canvas canvas, Rect rect, StyleMonde style) {
  final degrade = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [style.fondHaut, style.fondBas])
      .createShader(rect);
  canvas.drawRect(rect, Paint()..shader = degrade);
}

/* le tour de la carte du monde : un trait au bord du globe, arrondi
   comme les coins de la carte ; contreEchelle garde une epaisseur
   constante a l ecran quel que soit le zoom */
void contourMonde(
    Canvas canvas, Rect rect, double contreEchelle, StyleMonde style) {
  final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.75 * contreEchelle),
      Radius.circular(12 * contreEchelle));
  canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = style.contour
        ..strokeWidth = 1.5 * contreEchelle
        ..isAntiAlias = true);
}

/* la zone de nuit : la courbe terminatrice puis la fermeture par le
   pole en nuit, remplie du voile de nuit du style choisi ; c est la
   nuit qui est teintee, le jour reste clair */
void dessineZoneNuit(Canvas canvas,
    Offset Function(double, double) versPlan, DateTime heure, StyleMonde style) {
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
  canvas.drawPath(path, Paint()..color = style.voileNuit);
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