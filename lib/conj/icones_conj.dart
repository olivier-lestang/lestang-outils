/* Les icones de conjugaison : un petit drapeau et les deux lettres de la
   langue, posees dessus dans une pastille foncee.
   Une icone coloree par langue, y compris l anglais.
   SPDX-License-Identifier : MIT. */
import 'dart:math' as math;

import 'package:flutter/material.dart';

const _drapeaux = <String, List<Color>>{
  'es': [Color(0xffaa151b), Color(0xfff1bf00), Color(0xffaa151b)],
  'de': [Color(0xff000000), Color(0xffdd0000), Color(0xffffce00)],
  'pl': [Color(0xffffffff), Color(0xffdc143c)],
  'cs': [Color(0xffffffff), Color(0xffd7141a), Color(0xff11489e)],
};

/* Les tricolores a bandes verticales : france, italie, roumanie. */
const _verticaux = <String, List<Color>>{
  'fr': [Color(0xff0055a4), Color(0xffffffff), Color(0xffef4135)],
  'it': [Color(0xff008c45), Color(0xfff4f5f0), Color(0xffcd212a)],
  'ro': [Color(0xff002b7f), Color(0xfffcd116), Color(0xffce1126)],
};

/* Le portugal : vert sur deux cinquiemes, rouge sur trois. */
const _pt = [Color(0xff046a38), Color(0xffda291c)];

const _codes = <String, String>{
  'fr': 'FR',
  'en': 'EN',
  'es': 'ES',
  'it': 'IT',
  'pt': 'PT',
  'de': 'DE',
  'pl': 'PL',
  'cs': 'CS',
  'ro': 'RO',
};

/* Le drapeau lui-meme : des bandes pleines, verticales ou horizontales,
   dans un petit rectangle arrondi. */
Widget _etendard(String langue) {
  final arrondi = BorderRadius.circular(3);
  if (langue == 'en') {
    return ClipRRect(borderRadius: arrondi, child: _unionJack());
  }
  if (langue == 'pt') {
    return ClipRRect(
      borderRadius: arrondi,
      child: SizedBox(
        width: 24,
        height: 16,
        child: Row(children: [
          const Expanded(flex: 2, child: ColoredBox(color: _pt[0])),
          const Expanded(flex: 3, child: ColoredBox(color: _pt[1])),
        ]),
      ),
    );
  }
  final verticaux = _verticaux[langue];
  if (verticaux != null) {
    return ClipRRect(
      borderRadius: arrondi,
      child: SizedBox(
        width: 24,
        height: 16,
        child: Row(children: [
          for (final c in verticaux) Expanded(child: ColoredBox(color: c)),
        ]),
      ),
    );
  }
  final bandes = _drapeaux[langue] ?? const [Color(0xff7d1f2e)];
  return ClipRRect(
    borderRadius: arrondi,
    child: SizedBox(
      width: 24,
      height: 16,
      child: Column(children: [
        for (final c in bandes) Expanded(child: ColoredBox(color: c)),
      ]),
    ),
  );
}

/* L union jack simplifie : fond bleu, sautoirs blanc puis rouge, croix
   blanche puis croix rouge par-dessus. */
Widget _unionJack() {
  const bleu = Color(0xff012169);
  const blanc = Color(0xffffffff);
  const rouge = Color(0xffc8102e);
  const w = 24.0, h = 16.0;
  final diag = math.atan2(h, w);
  Widget sautoir(Color couleur, double epaisseur) => Transform.rotate(
        angle: diag,
        child: Container(
            width: 34, height: epaisseur, color: couleur), // diagonale /
      );
  Widget sautoirCroise(Color couleur, double epaisseur) => Transform.rotate(
        angle: -diag,
        child: Container(
            width: 34, height: epaisseur, color: couleur), // diagonale \
      );
  return SizedBox(
    width: w,
    height: h,
    child: Stack(alignment: Alignment.center, children: [
      const Positioned.fill(child: ColoredBox(color: bleu)),
      // les deux sautoirs, blanc large puis rouge etroit
      sautoir(blanc, 5),
      sautoirCroise(blanc, 5),
      sautoir(rouge, 2.5),
      sautoirCroise(rouge, 2.5),
      // la croix droite : blanc large puis rouge etroit
      Align(
        alignment: Alignment.center,
        child: Container(width: w, height: 6, color: blanc),
      ),
      Align(
        alignment: Alignment.center,
        child: Container(width: 6, height: h, color: blanc),
      ),
      Align(
        alignment: Alignment.center,
        child: Container(width: w, height: 3, color: rouge),
      ),
      Align(
        alignment: Alignment.center,
        child: Container(width: 3, height: h, color: rouge),
      ),
    ]),
  );
}

/* L icone d une langue de conjugaison : drapeau 22x15 en bandes arrondies
   plus les deux lettres sur une pastille semi-transparente. */
Widget iconeConjug(String langue) {
  final code = _codes[langue] ?? langue.toUpperCase();
  return SizedBox(
    width: 26,
    height: 24,
    child: Stack(alignment: Alignment.center, children: [
      /* le drapeau, legerement agrandi pour rester lisible */
      Transform.translate(
        offset: const Offset(0, -1),
        child: _etendard(langue),
      ),
      /* les deux lettres de la langue, sur une pastille foncee */
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        decoration: BoxDecoration(
            color: Colors.black.withOpacity(.65),
            borderRadius: BorderRadius.circular(3)),
        child: Text(code,
            style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1)),
      ),
    ]),
  );
}
