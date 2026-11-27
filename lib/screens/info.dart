/* Information: licences and heritage of the project.
   SPDX-License-Identifier: MIT. */
import 'package:flutter/material.dart';

import '../l10n.dart';

class InfoScreen extends StatelessWidget {
  final Translator trad;
  const InfoScreen(this.trad, {super.key});

  @override
  Widget build(BuildContext context) {
    final style = const TextStyle(fontSize: 13);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Lestang Outils',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      const Text(
          'Conjugaison : anglais 19 070, italien 12 429, polonais 9 064, '
          'roumain 6 970, '
          'français 8 535, espagnol 8 957, '
          'portugais 6 084, allemand 4 220, tchèque 4 143 ; '
          'enrichis et vérifiés depuis le Wiktionary via kaikki.org '
          '(CC BY-SA 4.0), verbes du Wiktionary intégralement conservés, '
          'chaque verbe a une définition (les verbes sans définition '
          'ont été comblés depuis les Wiktionary monolingues, '
          'CC BY-SA 4.0) ; '
          'définitions françaises du Dictionnaire de l Académie française '
          '( 8e éd., 1932-1935 ) et du Littré, anglaises du Webster 1913 '
          '(domaine public, numérisation lunixbochs/webster) et espagnoles '
          'de la Real Academia ( 1913-1914 ) : domaine public ; '
          'pour l allemand, l italien et le portugais : glossaires anglais '
          'du Wiktionary ( CC BY-SA 4.0 ) ; pour le polonais, le tchèque et '
          'le roumain : définitions natives des Wiktionary monolingues '
          '( CC BY-SA 4.0 ), complétées par les glossaires anglais du '
          'Wiktionary ; '
          'chaque fiche indique la source du verbe ; temps composés '
          'calculés sur votre appareil.',
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
          'définitions allemandes viennent du '
          'glossaire du générateur du projet ( SPDX-License-Identifier : MIT ). '
          'Les définitions françaises viennent du Dictionnaire de l Académie '
          'française ( 8e édition, 1932-1935 ) et du Littré ( 1872-1877 ), '
          'les anglaises du Webster 1913 ( numérisation '
          'lunixbochs/webster, code MIT ) et les espagnoles de la Real '
          'Academia ( 1913-1914 ) : domaine public, complétées par des '
          'rédactions du projet ; les définitions italiennes et portugaises '
          'sont les glossaires anglais du Wiktionary '
          '( CC BY-SA 4.0 ) ; les définitions polonaises, tchèques et '
          'roumaines viennent en priorité des Wiktionary monolingues '
          '( dumps pl., cs. et ro.wiktionary, CC BY-SA 4.0 ) et pour le '
          'reste des glossaires anglais du Wiktionary en traduction '
          '( CC BY-SA 4.0, attribution « Wiktionary contributors », '
          'extraction kaikki.org ). La compression PDF rastérise page par page '
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