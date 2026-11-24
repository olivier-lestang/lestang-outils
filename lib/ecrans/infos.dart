/* Informations : licences et heritage du projet.
   SPDX-License-Identifier : MIT. */
import 'package:flutter/material.dart';

import '../l10n.dart';

class EcranInfos extends StatelessWidget {
  final Traducteur trad;
  const EcranInfos(this.trad, {super.key});

  @override
  Widget build(BuildContext context) {
    final style = const TextStyle(fontSize: 13);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Lestang Outils',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      const Text(
          'Conjugaison : anglais 40 327, italien 12 429, espagnol 8 981, '
          'français 8 539, polonais 9 102, portugais 6 085, allemand 4 220, '
          'tchèque 4 151 ; '
          'enrichis et vérifiés depuis le Wiktionary via kaikki.org '
          '(CC BY-SA 4.0) ; chaque fiche indique la source du verbe ; '
          'temps composés calculés '
          'sur votre appareil ; définitions dans la langue de chaque carte.',
          style: TextStyle(fontSize: 13)),
      const SizedBox(height: 8),
      Text(
          'Cartes géographiques : départements, routes ( 2 461 autoroutes, '
          '2 884 nationales, 50 984 départementales ), fleuves, ZEE et lignes '
          'à grande vitesse de France ; membres et voisins de l Union '
          'européenne, routes européennes ; frontières du monde.',
          style: style),
      const SizedBox(height: 8),
      Text(
          'Licences : le code est sous licence MIT. Les conjugaisons et les '
          'définitions allemandes, italiennes et portugaises viennent du '
          'glossaire du générateur du projet ( SPDX-License-Identifier : MIT ). '
          'Les définitions françaises viennent du Dictionnaire de l Académie '
          'française ( 8e édition, 1932-1935 ) et du Littré ( 1872-1877 ), '
          'les anglaises du Webster 1913 ( GCIDE ), les espagnoles de la Real '
          'Academia ( 1913-1914 ) : domaine public, complétées par des '
          'rédactions du projet. La compression PDF rastérise page par page '
          'via pdfium ( package printing ), JPEG via package image, '
          'reconstruction via package pdf ; ces bibliotheques, ainsi que '
          'share_plus ( feuille de partage sous Android ), sont sous '
          'licence MIT ou apparentee Apache.',
          style: style),
      const SizedBox(height: 8),
      Text(
          'Météo : Météo-France, MET Norvège, IPMA Portugal, JMA Japon, NWS États-Unis, BOM Australie, HKO Hong Kong, Open-Meteo et wttr.in ; source nationale par pays, sans clé.',
          style: style),
    ]);
  }
}
