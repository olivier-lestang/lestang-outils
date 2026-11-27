/* Les icones de conjugaison : un petit drapeau en bandes horizontales et
   les deux lettres de la langue, poses dessus dans une pastille foncee.
   Une icone coloree par langue, y compris l anglais.
   SPDX-License-Identifier : MIT. */
import 'package:flutter/material.dart';

const _drapeaux = <String, List<Color>>{
  'fr': [Color(0xff0055a4), Color(0xffffffff), Color(0xffef4135)],
  'en': [Color(0xff012169), Color(0xffffffff), Color(0xffc8102e)],
  'es': [Color(0xffaa151b), Color(0xfff1bf00), Color(0xffaa151b)],
  'it': [Color(0xff008c45), Color(0xfff4f5f0), Color(0xffcd212a)],
  'pt': [Color(0xff046a38), Color(0xffda291c)],
  'de': [Color(0xff000000), Color(0xffdd0000), Color(0xffffce00)],
  'pl': [Color(0xffffffff), Color(0xffdc143c)],
  'cs': [Color(0xffffffff), Color(0xffd7141a), Color(0xff11489e)],
  'ro': [Color(0xff002b7f), Color(0xfffcd116), Color(0xffce1126)],
};

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

/* L icone d une langue de conjugaison : drapeau 22x15 en bandes arrondies
   plus les deux lettres sur une pastille semi-transparente. */
Widget iconeConjug(String langue) {
  final bandes = _drapeaux[langue] ?? const [Color(0xff7d1f2e)];
  final code = _codes[langue] ?? langue.toUpperCase();
  return SizedBox(
    width: 26,
    height: 24,
    child: Stack(alignment: Alignment.center, children: [
      /* le drapeau, legerement agrandi pour rester lisible */
      Transform.translate(
        offset: const Offset(0, -1),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            width: 24,
            height: 16,
            child: Column(children: [
              for (final c in bandes) Expanded(child: Container(color: c)),
            ]),
          ),
        ),
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
