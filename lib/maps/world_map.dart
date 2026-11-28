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
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Canvas;

import 'package:flutter/material.dart';

import '../database.dart' as db;
import 'map_styles.dart';
import 'world_data.dart';
import 'world_projection.dart';

/* the layers and points of the world map in the database */
const worldLayers = <String>['frontieres'];
const worldPoints = <String>['villes'];

/* a world map style: gradient background, land, borders, night veil,
   graticule and outline, the WM_STYLES values of the web */
class WorldStyle {
  final Color bgTop, bgBottom, land, border, nightShade, grid, outline;
  const WorldStyle({
    required this.bgTop,
    required this.bgBottom,
    required this.land,
    required this.border,
    required this.nightShade,
    required this.grid,
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
      grid: Color(0x59ffffff),
      outline: Color(0xffe9e4d3)),
  'nuit': WorldStyle(
      bgTop: Color(0xff090d1c),
      bgBottom: Color(0xff141d38),
      land: Color(0xff2c3452),
      border: Color(0x809aa6c8),
      nightShade: Color(0x8000000c),
      grid: Color(0x4dbecdff),
      outline: Color(0xff9aa6c8)),
  'encre': WorldStyle(
      bgTop: Color(0xfff3edde),
      bgBottom: Color(0xffe6dcc3),
      land: Color(0xff31405f),
      border: Color(0x8c96b4e6),
      nightShade: Color(0x38302858),
      grid: Color(0x5931405f),
      outline: Color(0xff31405f)),
  'croquis': WorldStyle(
      bgTop: Color(0xf2eee9da),
      bgBottom: Color(0xf2e2dccb),
      land: Color(0xfffaf6ec),
      border: Color(0x801c2232),
      nightShade: Color(0x290a0c16),
      grid: Color(0x8c1c2232),
      outline: Color(0xff1c2232)),
};

/* World: raw lon and lat, projected at draw time in Equal Earth or in
   the equirectangular fallback of the web ( wmER ); the style comes
   from the settings dialog, ocean by default */
MapSettings worldSettings(bool light, [WorldStyle? style, bool equalEarth = true]) {
  final st = style ?? worldStyles['ocean']!;
  final aspect = equalEarth ? eeAspect : 2.0;
  return MapSettings(
    {
      'frontieres': StrokeStyle(st.border, 0.4, fill: st.land, closes: true),
    },
    {
      'villes': PointStyle(const Color(0xffe03131), 1.8, minZoom: -1),
    },
    {
      /* the labels only appear on zoom: at the scale of the whole
         world they would pile up, the web shows none */
      'villes': 3.5,
    },
    Rect.fromLTRB(-aspect, 1, aspect, -1),
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
    DateTime time, WorldStyle style, double center,
    {double aspect = eeAspect, bool equalEarth = true}) {
  final sun = subsolarPoint(time.toUtc());
  final polygon =
      nightPolygon(sun, meridian: center, equalEarth: equalEarth);
  final path = Path();
  var first = true;
  for (final vertex in polygon) {
    final pos = toPlane(vertex.dx * aspect, vertex.dy);
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
    double limit, double center,
    {bool equalEarth = true}) {
  final inv = equalEarth
      ? eeInv(px / eeAspect, py)
      : <double>[px * 90.0, py * 90.0];
  db.NamedPoint? closest;
  var best = 1e9;
  double recentered(double lon) => ((lon - center + 540) % 360) - 180;
  for (final v in cities) {
    /* the plane of a candidate: Equal Earth stretches its normalised
       position to the aspect of the oval, the flat world halves the
       degrees ( lon / 90 ); the doubled x of the flat mode used to
       read a city two longitudes away from the finger */
    final p = equalEarth
        ? ee(v.y, recentered(v.x))
        : Offset(recentered(v.x) / 90.0, v.y / 90.0);
    final cx = equalEarth ? p.dx * eeAspect : p.dx;
    final dd = (cx - px) * (cx - px) + (p.dy - py) * (p.dy - py);
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

/* ---------------- the sun, the graticule and the time zones of the web ---------------- */

/* draws a path with a dash motif counter-scaled by the zoom, the
   dashes keep a constant on-screen size */
void _dashed(Canvas canvas, Path path, Paint paint, List<double> motif,
    double inverseScale) {
  for (final piece in path.computeMetrics()) {
    double moved = 0;
    final total = piece.length;
    var k = 0;
    while (moved < total) {
      final step = motif[k % motif.length] * inverseScale;
      final end = math.min(moved + step, total);
      canvas.drawPath(piece.extractPath(moved, end), paint);
      moved = end + motif[(k + 1) % motif.length] * inverseScale;
      k += 2;
    }
  }
}

/* the equator, the tropics and the polar circles: the parallels are
   straight lines in both projections, dashed like on the web ( the
   equator plain, the tropics long dashes, the polar circles short
   dashes ). The parallel is sampled over the whole window of the
   center, from one edge meridian to the other: both raw edge
   longitudes are the same meridian once wrapped, a single chord
   between them would have been zero long and nothing showed */
void drawGraticule(Canvas canvas, Offset Function(double, double) project,
    WorldStyle style, double inverseScale, double center) {
  const lines = <List<Object>>[
    [0.0, <double>[]],
    [23.4368, [5.0, 5.0]],
    [-23.4368, [5.0, 5.0]],
    [66.5632, [2.0, 6.0]],
    [-66.5632, [2.0, 6.0]],
  ];
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..color = style.grid
    ..strokeWidth = inverseScale
    ..isAntiAlias = true;
  for (final l in lines) {
    final lat = l[0] as double;
    final motif = l[1] as List<double>;
    final path = Path();
    var first = true;
    for (var c = center - 180.0; c <= center + 180.0 + 1e-9; c += 2.0) {
      final q = project(c, lat);
      if (first) {
        path.moveTo(q.dx, q.dy);
        first = false;
      } else {
        path.lineTo(q.dx, q.dy);
      }
    }
    if (motif.isEmpty) {
      canvas.drawPath(path, paint);
    } else {
      _dashed(canvas, path, paint, motif, inverseScale);
    }
  }
}

/* the time zone borders clipped at the seam, one cache per center:
   the Natural Earth lines of world_data.dart, cut like the country
   rings ( wmRingClip then wmStrokeClipped, dotted like the web ) */
final Map<double, List<List<double>>> _tzClipCache = {};

List<List<double>> tzPieces(double center) {
  final cached = _tzClipCache[center];
  if (cached != null) return cached;
  final out = <List<double>>[];
  for (final border in worldTzBorders) {
    final ring = Float32List.fromList(border);
    for (final piece in ringClip(ring, center)) {
      out.add(piece);
    }
  }
  _tzClipCache[center] = out;
  return out;
}

void drawTimeZones(Canvas canvas, Offset Function(double, double) project,
    WorldStyle style, double center, double inverseScale) {
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..color = style.grid
    ..strokeWidth = inverseScale
    ..isAntiAlias = true;
  for (final piece in tzPieces(center)) {
    final path = Path();
    strokeClipped(path, piece, center, project);
    _dashed(canvas, path, paint, const [4.0, 6.0], inverseScale);
  }
}

/* the subsolar point: the sun stands at the zenith there, a yellow
   dot with a dark rim like on the web */
void drawSunSpot(Canvas canvas, Offset Function(double, double) project,
    DateTime time, double center, double inverseScale) {
  final sun = subsolarPoint(time.toUtc());
  /* the longitude is brought into the window of the center, the
     projector expects a window longitude */
  var lon = sun.lon;
  while (lon > center + 180) {
    lon -= 360;
  }
  while (lon < center - 180) {
    lon += 360;
  }
  final pos = project(lon, sun.lat);
  canvas.drawCircle(
      pos,
      6 * inverseScale,
      Paint()
        ..color = const Color(0xf2ffd640)
        ..isAntiAlias = true);
  canvas.drawCircle(
      pos,
      6 * inverseScale,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0x80785000)
        ..strokeWidth = inverseScale
        ..isAntiAlias = true);
}

/* ---------------- the contested borders of the web ---------------- */

/* the eight conflicts of the web menu: the key, the French title of
   the group and its two views; an empty value stays neutral
   ( dotted or ordinary border, no side taken ) */
const disputedGroups = <String, List<String>>{
  'crimee': ['Crimée', 'Vue ukrainienne', 'Vue russe'],
  'kashmir': ['Cachemire et Aksai Chin', 'Vue indienne', 'Vue pakistanaise'],
  'taiwan': ['Taïwan et revendications chinoises', 'Vue chinoise', ''],
  'wsahara': ['Sahara occidental', 'Vue marocaine', ''],
  'kosovo': ['Kosovo', 'Vue serbe', ''],
  'chypre': ['Chypre', 'Île unie', ''],
  'golan': ['Golan', 'Rattaché à la Syrie', ''],
  'essequibo': ['Essequibo', 'Vue vénézuélienne', ''],
};

/* the state of the contested borders given the menu choices: the
   boxes inside which the solid stroke skips ( [ west, east, south,
   north ] ), and the polylines redrawn as dotted segments; the
   choices of the web menu, box by box */
class DisputedState {
  final List<List<double>> skipBoxes;
  final List<List<List<double>>> dotted;
  const DisputedState(this.skipBoxes, this.dotted);
}

void _addBox(List<List<double>> boxes, List<List<double>> overlay) {
  var w = 1e9, e = -1e9, s = 1e9, n = -1e9;
  for (final p in overlay) {
    if (p[0] < w) w = p[0];
    if (p[0] > e) e = p[0];
    if (p[1] < s) s = p[1];
    if (p[1] > n) n = p[1];
  }
  boxes.add([w, e, s, n]);
}

DisputedState disputedState(Map<String, String> conflicts) {
  final boxes = <List<double>>[];
  final dotted = <List<List<double>>>[];
  final c = (String k) => conflicts[k] ?? '';
  /* Crimea: Ukrainian view, the peninsula is connected to the
     mainland, no border; Russian view, the isthmus border is drawn;
     neutral, the isthmus is dotted ( WM_DISPUTED of the web ) */
  if (c('crimee') == 'ua' || c('crimee') != 'ru') {
    boxes.add([33.35, 35.05, 45.65, 46.25]);
    if (c('crimee') != 'ua') dotted.add(disputedOverlays['crimee']!);
  }
  /* Kashmir: Indian view, the line of control is not a border; neutral,
     the line is dotted; Pakistani view, it stays a solid border */
  if (c('kashmir') == 'in' || c('kashmir') != 'pk') {
    boxes.add([73.55, 76.0, 32.2, 34.8]);
    if (c('kashmir') != 'in') dotted.add(disputedOverlays['cachemire']!);
  }
  /* Aksai Chin follows the Kashmir checkbox since the merge of the
     web: Indian view, the effective line of control is not a border */
  if (c('kashmir') == 'in') boxes.add([77.4, 79.6, 32.2, 35.9]);
  /* Taiwan, province of China in this view: no administrative
     outline, the McMahon line of Arunachal is erased and the Senkaku
     / Diaoyu are dotted */
  if (c('taiwan') == 'cn') {
    boxes.add([119.0, 124.0, 20.5, 25.6]);
    _addBox(boxes, disputedOverlays['arunachal']!);
    dotted.add(disputedOverlays['senkaku']!);
  }
  /* merged views: the shared boundary disappears on both sides
     ( Western Sahara, Kosovo, Cyprus, Golan, Essequibo ) */
  if (c('wsahara') == 'ma') _addBox(boxes, disputedOverlays['berm']!);
  if (c('kosovo') == 'rs') _addBox(boxes, disputedOverlays['kosovo']!);
  if (c('chypre') == 'unie') _addBox(boxes, disputedOverlays['chypre']!);
  if (c('golan') == 'syrien') _addBox(boxes, disputedOverlays['golan']!);
  if (c('essequibo') == 've') _addBox(boxes, disputedOverlays['essequibo']!);
  return DisputedState(boxes, dotted);
}

/* is a segment of a ring inside one of the skip boxes? */
bool disputedSkip(List<List<double>> boxes, double x1, double y1,
    double x2, double y2) {
  for (final b in boxes) {
    if (x1 >= b[0] && x1 <= b[1] && y1 >= b[2] && y1 <= b[3] &&
        x2 >= b[0] && x2 <= b[1] && y2 >= b[2] && y2 <= b[3]) {
      return true;
    }
  }
  return false;
}

/* the dotted overlays: real round dots laid along the projected path
   every 4.5 px, like the web ( a dash motif would read as a solid
   stroke at world scale ) */
void drawDisputedDotted(Canvas canvas, Offset Function(double, double) project,
    Color color, List<List<List<double>>> overlays, double center,
    double inverseScale) {
  final paint = Paint()..color = color;
  for (final overlay in overlays) {
    final pts = <Offset>[];
    for (final p in overlay) {
      /* each longitude is brought into the window of the center, the
         projector expects a window longitude */
      var lon = p[0];
      while (lon > center + 180) {
        lon -= 360;
      }
      while (lon < center - 180) {
        lon += 360;
      }
      pts.add(project(lon, p[1]));
    }
    var total = 0.0;
    for (var i = 1; i < pts.length; i++) {
      total += (pts[i] - pts[i - 1]).distance;
    }
    if (total <= 0) continue;
    final count = math.max(1, (total / (4.5 * inverseScale)).floor());
    for (var i = 0; i <= count; i++) {
      var walk = total * i / count, done = 0.0;
      for (var j = 1; j < pts.length; j++) {
        final seg = (pts[j] - pts[j - 1]).distance;
        if (walk <= done + seg) {
          final t = seg == 0 ? 0.0 : (walk - done) / seg;
          canvas.drawCircle(
              Offset.lerp(pts[j - 1], pts[j], t)!,
              1.25 * inverseScale,
              paint);
          break;
        }
        done += seg;
      }
    }
  }
}