/* The conjugation icons: a small flag and the two letters of the
   language, laid over it on a dark badge.
   One coloured icon per language, English included.
   SPDX-License-Identifier: MIT. */
import 'dart:math' as math;

import 'package:flutter/material.dart';

/* A 24x16 flag: solid stripes laid side by side ( DecoratedBox, fixed
   sizes, no Expanded or ColoredBox which do not render in the icon
   slot of the NavigationRail ). */
Widget _stripe(Color c, double w, double h) => DecoratedBox(
    decoration: BoxDecoration(color: c), child: SizedBox(width: w, height: h));

/* The horizontal-stripe flags: spain, germany, poland, czechia. */
const _horizontalFlags = <String, List<Color>>{
  'es': [Color(0xffaa151b), Color(0xfff1bf00), Color(0xffaa151b)],
  'de': [Color(0xff000000), Color(0xffdd0000), Color(0xffffce00)],
  'pl': [Color(0xffffffff), Color(0xffdc143c)],
  'cs': [Color(0xffffffff), Color(0xffd7141a), Color(0xff11489e)],
};

/* The vertical-stripe tricolours: france ( 2020 charter, France blue
   and Marianne red ), italy, romania. */
const _verticalFlags = <String, List<Color>>{
  'fr': [Color(0xff000091), Color(0xffffffff), Color(0xffe1000f)],
  'it': [Color(0xff008c45), Color(0xfff4f5f0), Color(0xffcd212a)],
  'ro': [Color(0xff002b7f), Color(0xfffcd116), Color(0xffce1126)],
};

/* Portugal: green over two fifths, red over three. */
const _ptGreen = Color(0xff046a38);
const _ptRed = Color(0xffda291c);

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

/* The flag itself, in a small rounded rectangle. */
Widget _flag(String language) {
  final rounding = BorderRadius.circular(3);
  if (language == 'en') {
    return ClipRRect(borderRadius: rounding, child: _unionJack());
  }
  Widget solid(List<Color> colors, bool horizontal) {
    final n = colors.length;
    return ClipRRect(
      borderRadius: rounding,
      child: SizedBox(
        width: 24,
        height: 16,
        child: horizontal
            ? Column(children: [
                for (final c in colors) _stripe(c, 24, 16 / n),
              ])
            : Row(children: [
                for (final c in colors) _stripe(c, 24 / n, 16),
              ]),
      ),
    );
  }

  if (language == 'pt') {
    return ClipRRect(
      borderRadius: rounding,
      child: SizedBox(
        width: 24,
        height: 16,
        child: Row(children: [
          _stripe(_ptGreen, 24 * 2 / 5, 16),
          _stripe(_ptRed, 24 * 3 / 5, 16),
        ]),
      ),
    );
  }
  final vertical = _verticalFlags[language];
  if (vertical != null) return solid(vertical, false);
  final stripes = _horizontalFlags[language] ?? const [Color(0xff7d1f2e)];
  return solid(stripes, true);
}

/* The simplified union jack: blue background, white then red saltires,
   white cross then red cross on top. */
Widget _unionJack() {
  const blue = Color(0xff012169);
  const white = Color(0xffffffff);
  const red = Color(0xffc8102e);
  const w = 24.0, h = 16.0;
  final diag = math.atan2(h, w);
  Widget saltire(Color color, double thickness) => Transform.rotate(
        angle: diag,
        child: Container(
            width: 34, height: thickness, color: color), // diagonal /
      );
  Widget saltireCrossed(Color color, double thickness) => Transform.rotate(
        angle: -diag,
        child: Container(
            width: 34, height: thickness, color: color), // diagonal \
      );
  return SizedBox(
    width: w,
    height: h,
    child: Stack(alignment: Alignment.center, children: [
      const Positioned.fill(child: ColoredBox(color: blue)),
      // the two saltires, wide white then narrow red
      saltire(white, 5),
      saltireCrossed(white, 5),
      saltire(red, 2.5),
      saltireCrossed(red, 2.5),
      // the upright cross: wide white then narrow red
      Align(
        alignment: Alignment.center,
        child: Container(width: w, height: 6, color: white),
      ),
      Align(
        alignment: Alignment.center,
        child: Container(width: 6, height: h, color: white),
      ),
      Align(
        alignment: Alignment.center,
        child: Container(width: w, height: 3, color: red),
      ),
      Align(
        alignment: Alignment.center,
        child: Container(width: 3, height: h, color: red),
      ),
    ]),
  );
}

/* The icon of a conjugation language: the flag plus the two letters of
   the language on a semi-transparent badge. */
Widget conjugIcon(String language) {
  final code = _codes[language] ?? language.toUpperCase();
  return SizedBox(
    width: 26,
    height: 24,
    child: Stack(alignment: Alignment.center, children: [
      /* the flag, slightly raised to stay readable */
      Transform.translate(
        offset: const Offset(0, -1),
        child: _flag(language),
      ),
      /* the two letters of the language, on a dark badge */
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