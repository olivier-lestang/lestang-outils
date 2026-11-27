/* The world map: settings, background, night zone and tooltip, in its
   own file, distinct from the European Union map and the French
   overseas territories. The colours follow the four styles of the last
   web HTML ( WM_STYLES of js/monde/carte-monde.js ): ocean, night, ink
   and sketch, chosen in the settings dialog of the map; the style does
   not depend on the light or dark theme, like on the web.
   The seam mathematics ( ringClip, strokeClipped, edge sampling ) is
   the Dart port of wmRingClip and wmStrokeClipped of the same web
   file: recentered Equal Earth, the ring unfolds into continuous
   longitudes, is cut at the two edge meridians, then repeated at
   -360/+360 for the part straddling the seam, so no closing crosses
   the map and no inverted colour triangle appears any more, whatever
   the chosen center.
   SPDX-License-Identifier: MIT. */
import 'dart:ui' show Canvas;

import 'package:flutter/material.dart';

import '../database.dart' as db;
import 'map_styles.dart';
import 'world_projection.dart';

/* the layers and points of the world map in the database */
const worldLayers = <String>['frontieres'];
const worldPoints = <String>['villes'];

/* a world map style: gradient background, land, borders, night veil
   and outline, the WM_STYLES values of the web */
class WorldStyle {
  final Color bgTop, bgBottom, land, border, nightShade, outline;
  const WorldStyle({
    required this.bgTop,
    required this.bgBottom,
    required this.land,
    required this.border,
    required this.nightShade,
    required this.outline,
  });
}

/* the four web styles, same values in both themes:
   ocean ( default ), night, ink, sketch ( WM_STYLES ) */
const worldStyles = <String, WorldStyle>{
  'ocean': WorldStyle(
      bgTop: Color(0xff0b2f63),
      bgBottom: Color(0xff155399),
      land: Color(0xffe9e4d3),
      border: Color(0x8c5a6e87),
      nightShade: Color(0x73030816),
      outline: Color(0xffe9e4d3)),
  'nuit': WorldStyle(
      bgTop: Color(0xff090d1c),
      bgBottom: Color(0xff141d38),
      land: Color(0xff2c3452),
      border: Color(0x809aa6c8),
      nightShade: Color(0x8000000c),
      outline: Color(0xff9aa6c8)),
  'encre': WorldStyle(
      bgTop: Color(0xfff3edde),
      bgBottom: Color(0xffe6dcc3),
      land: Color(0xff31405f),
      border: Color(0x8c96b4e6),
      nightShade: Color(0x38302858),
      outline: Color(0xff31405f)),
  'croquis': WorldStyle(
      bgTop: Color(0xf2eee9da),
      bgBottom: Color(0xf2e2dccb),
      land: Color(0xfffaf6ec),
      border: Color(0x801c2232),
      nightShade: Color(0x290a0c16),
      outline: Color(0xff1c2232)),
};

/* World: raw lon and lat, projected in Equal Earth at draw time; the
   style comes from the settings dialog, ocean by default */
MapSettings worldSettings(bool light, [WorldStyle? style]) {
  final st = style ?? worldStyles['ocean']!;
  return MapSettings(
    {
      'frontieres': StrokeStyle(st.border, 0.4, fill: st.land, closes: true),
    },
    {
      'villes': PointStyle(const Color(0xffe03131), 1.8, minZoom: -1),
    },
    {
      'villes': -1,
    },
    const Rect.fromLTRB(-eeAspect, 1, eeAspect, -1),
  );
}

/* the gradient background of the world, like the canvas background of
   the web ( vertical linear gradient from bg[0] to bg[1] of the chosen
   style ), painted only inside the rectangle of the map: the outline
   is drawn by worldOutline, so the globe stands out from the screen
   background around it */
void worldBackground(Canvas canvas, Rect rect, WorldStyle style) {
  final gradient = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [style.bgTop, style.bgBottom])
      .createShader(rect);
  canvas.drawRect(rect, Paint()..shader = gradient);
}

/* the outline of the world map: a stroke at the edge of the globe,
   rounded like the corners of the map; inverseScale keeps a constant
   on-screen width whatever the zoom */
void worldOutline(
    Canvas canvas, Rect rect, double inverseScale, WorldStyle style) {
  final rrect = RRect.fromRectAndRadius(
      rect.deflate(1.25 * inverseScale),
      Radius.circular(12 * inverseScale));
  canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = style.outline
        ..strokeWidth = 2.5 * inverseScale
        ..isAntiAlias = true);
}

/* the night zone: the terminator curve then the closing through the
   pole in night, filled with the night veil of the chosen style; the
   night is shaded, the day stays clear */
void drawNightZone(Canvas canvas, Offset Function(double, double) toPlane,
    DateTime time, WorldStyle style, double center) {
  final sun = subsolarPoint(time.toUtc());
  final polygon = nightPolygon(sun, meridian: center);
  final path = Path();
  var first = true;
  for (final vertex in polygon) {
    final pos = toPlane(vertex.dx * eeAspect, vertex.dy);
    if (first) {
      path.moveTo(pos.dx, pos.dy);
      first = false;
    } else {
      path.lineTo(pos.dx, pos.dy);
    }
  }
  path.close();
  canvas.drawPath(path, Paint()..color = style.nightShade);
}

/* the tooltip of the world: the city closest to the finger, otherwise
   the inverted longitude and latitude of the projection; px and py are
   the coordinates of the touched plane, limit bounds the city radius in
   plane units */
String worldTooltip(double px, double py, List<db.NamedPoint> cities,
    double limit, double center) {
  final inv = eeInv(px / eeAspect, py);
  db.NamedPoint? closest;
  var best = 1e9;
  double recentered(double lon) => ((lon - center + 540) % 360) - 180;
  for (final v in cities) {
    final p = ee(v.y, recentered(v.x));
    final dd = (p.dx * eeAspect - px) * (p.dx * eeAspect - px) +
        (p.dy - py) * (p.dy - py);
    if (dd < best) {
      best = dd;
      closest = v;
    }
  }
  if (closest != null && closest.name.isNotEmpty && best < limit) {
    return closest.name + (closest.info.isEmpty ? '' : ' · ${closest.info}');
  }
  final lon = ((inv[0] + center + 540) % 360) - 180;
  return '${inv[1].toStringAsFixed(1)}°, ${lon.toStringAsFixed(1)}°';
}

/* ---------------- the seam mathematics of the web ( wmRingClip ) ---------------- */

/* Recentered Equal Earth: the ring unfolds into continuous longitudes,
   is cut at the two edge meridians ( center - 180 and center + 180 ),
   then repeated at -360/+360 for the part straddling the seam: never
   again a closing crossing the map or inverted colours, and the polar
   line always joins both edges.
   Each returned element: flat list [lon, lat, lon, lat, ...] closable
   as is, its longitudes already inside the window of the center. */
List<List<double>> ringClip(Float32List ring, double center) {
  final edgeW = center - 180.0, edgeE = center + 180.0;
  final r = <double>[];
  double? pvLon;
  double pvLat = 0;
  for (var i = 0; i + 1 < ring.length; i += 2) {
    var lo = ring[i].toDouble(), la = ring[i + 1].toDouble();
    if (pvLon == null) {
      while (lo > edgeE) {
        lo -= 360;
      }
      while (lo < edgeW) {
        lo += 360;
      }
    } else if (!(pvLat.abs() >= 89.99 && la.abs() >= 89.99)) {
      while (lo - pvLon > 180) {
        lo -= 360;
      }
      while (lo - pvLon < -180) {
        lo += 360;
      }
    }
    r.add(lo);
    r.add(la);
    pvLon = lo;
    pvLat = la;
  }
  /* ring encircling a pole: the tail is brought back into the frame of
     the head, the closing stays null and no diagonal paints the
     Weddell sea any more ( PATCH151 of the web ) */
  final pairs = ring.length ~/ 2;
  var pk2 = -1;
  for (var pi = 0; pi < pairs; pi++) {
    final paLat = ring[2 * pi + 1].toDouble(),
        pbLat = ring[2 * ((pi + 1) % pairs) + 1].toDouble();
    final paLon = ring[2 * pi].toDouble(),
        pbLon = ring[2 * ((pi + 1) % pairs)].toDouble();
    if (paLat.abs() >= 89.99 &&
        pbLat.abs() >= 89.99 &&
        (pbLon - paLon).abs() > 180) {
      pk2 = pi;
      break;
    }
  }
  if (pk2 >= 0) {
    final k2 = ((r[0] - r[r.length - 2]) / 360).round();
    if (k2 != 0) {
      for (var pj = 2 * (pk2 + 1); pj < r.length; pj += 2) {
        r[pj] += 360 * k2;
      }
    }
  }
  var rlo = 1e9, rhi = -1e9;
  for (var j = 0; j < r.length; j += 2) {
    if (r[j] < rlo) rlo = r[j];
    if (r[j] > rhi) rhi = r[j];
  }
  final out = <List<double>>[];
  /* copies: the part sticking out of one edge comes back through the
     other, like the wrapped world of the flat mode */
  for (var k = -1; k <= 1; k++) {
    if (rhi + 360.0 * k < edgeW || rlo + 360.0 * k > edgeE) continue;
    var p = <double>[];
    for (var jc = 0; jc < r.length; jc += 2) {
      p.add(r[jc] + 360.0 * k);
      p.add(r[jc + 1]);
    }
    /* Sutherland-Hodgman in longitude only: one pass per edge meridian */
    for (var pass = 0; pass < 2 && p.length >= 4; pass++) {
      final bound = pass == 1 ? edgeE : edgeW;
      final dir = pass == 1 ? 1 : -1;
      final q = <double>[];
      for (var sg = 0; sg < p.length; sg += 2) {
        final sg2 = (sg + 2) % p.length;
        final x1 = p[sg], y1 = p[sg + 1], x2 = p[sg2], y2 = p[sg2 + 1];
        final in1 = dir < 0 ? x1 >= bound - 1e-9 : x1 <= bound + 1e-9;
        final in2 = dir < 0 ? x2 >= bound - 1e-9 : x2 <= bound + 1e-9;
        if (in1 && in2) {
          q.add(x2);
          q.add(y2);
        } else if (in1 != in2) {
          final t = (bound - x1) / (x2 - x1);
          q.add(bound);
          q.add(y1 + (y2 - y1) * t);
          if (in2) {
            q.add(x2);
            q.add(y2);
          }
        }
      }
      p = q;
    }
    if (p.length >= 4) {
      /* the flank of the oval is curved: a straight closing along the
         seam meridian would become a chord cutting the earth on
         screen, it is sampled every two degrees */
      final pd = <double>[];
      for (var pe = 0; pe < p.length; pe += 2) {
        pd.add(p[pe]);
        pd.add(p[pe + 1]);
        final pe2 = (pe + 2) % p.length;
        if ((p[pe] - p[pe2]).abs() < 1e-9 &&
            ((p[pe] - edgeW).abs() < 1e-9 || (p[pe] - edgeE).abs() < 1e-9)) {
          final ya = p[pe + 1], yb = p[pe2 + 1];
          final stp = yb > ya ? 2.0 : -2.0;
          for (var yy = ya + stp;
              stp > 0 ? yy < yb - 1e-9 : yy > yb + 1e-9;
              yy += stp) {
            pd.add(p[pe]);
            pd.add(yy);
          }
        }
      }
      out.add(pd.length >= 4 ? pd : p);
    }
  }
  return out;
}

/* draws an already edge-clipped ring: the closing edges along an edge
   meridian are not stroked ( wmStrokeClipped of the web ) */
void strokeClipped(Path path, List<double> p, double center,
    Offset Function(double lon, double lat) project) {
  final edgeW = center - 180.0, edgeE = center + 180.0;
  var pen = false;
  final n = p.length ~/ 2;
  for (var i = 0; i < n; i++) {
    final x1 = p[2 * i], y1 = p[2 * i + 1];
    final jn = (2 * i + 2) % p.length;
    final x2 = p[jn], y2 = p[jn + 1];
    if ((x1 - x2).abs() < 1e-9 &&
        ((x1 - edgeW).abs() < 1e-9 || (x1 - edgeE).abs() < 1e-9)) {
      pen = false;
      continue;
    }
    final q1 = project(x1, y1), q2 = project(x2, y2);
    if (pen) {
      path.lineTo(q2.dx, q2.dy);
    } else {
      path.moveTo(q1.dx, q1.dy);
      path.lineTo(q2.dx, q2.dy);
      pen = true;
    }
  }
}