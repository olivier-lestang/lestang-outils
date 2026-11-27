/* Les styles communs des cartes geographiques : un style par couche de
   traits, un style par couche de points, et le paquet de reglages
   d une carte ( couches, points, seuils d etiquettes, cadrage ).
   SPDX-License-Identifier : MIT. */
import 'package:flutter/material.dart';

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
