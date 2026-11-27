/* The geographical maps: France ( with overseas territories ) and the
   European Union. The geometries come from the SQLite database, the
   rendering follows the colours of the web ( js/france, js/union ) in
   two light / dark palettes. The Union colours each member state; the
   painter and the screen stay generic, the world map lives in
   world_map.dart.
   SPDX-License-Identifier: MIT. */
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector4;

import '../database.dart' as db;
import 'departments.dart';
import 'map_settings.dart';
import 'map_styles.dart';
import 'union_palette.dart';
import 'world_clocks.dart';
import 'world_data.dart';
import 'world_map.dart';
import 'world_projection.dart';

/* ---------------- the styles ( map_styles.dart ) ---------------- */

/* France metropolis: x = lon * cos(46.245), y = lat */
MapSettings franceSettings(bool light) => MapSettings(
      {
        'departements': StrokeStyle(
            light ? const Color(0x33000000) : const Color(0x33ffffff), 0.6,
            fill: light ? const Color(0x14669933) : const Color(0x14669933),
            closes: true),
        'contour': StrokeStyle(
            light ? const Color(0xff495057) : const Color(0xffced4da), 1.2,
            closes: true),
        'autoroutes': StrokeStyle(
            light ? const Color(0xffc92a2a) : const Color(0xffff8787), 1.0),
        'nationales': StrokeStyle(
            light ? const Color(0xffe8590c) : const Color(0xffff922b), 0.8),
        'departementales': StrokeStyle(
            light ? const Color(0x88a8891c) : const Color(0x88d4b83a), 0.5),
        'fleuves': StrokeStyle(
            light ? const Color(0xff1971c2) : const Color(0xff74c0fc), 1.0),
        'zee': StrokeStyle(const Color(0x00000000), 0,
            fill: light ? const Color(0x221c7ed6) : const Color(0x22191970)),
        'lgv': StrokeStyle(
            light ? const Color(0xff6741d9) : const Color(0xff9775fa), 1.6,
            dashes: [4.0, 2.5]),
        'paris': StrokeStyle(
            light ? const Color(0xff862e9c) : const Color(0xffe64980), 0.8),
        'villes-transports': StrokeStyle(
            light ? const Color(0xff0b7285) : const Color(0xff3bc9db), 0.6),
      },
      {
        'grandes-villes': PointStyle(
            light ? const Color(0xff212529) : const Color(0xfff1f3f5), 2.2,
            minZoom: -1),
        'chefs-lieux': PointStyle(
            light ? const Color(0xff495057) : const Color(0xffadb5bd), 1.6,
            minZoom: 1.2),
        'villes': PointStyle(
            light ? const Color(0xff495057) : const Color(0xffadb5bd), 1.2,
            minZoom: 2.5),
        'stations': PointStyle(
            light ? const Color(0xffc2255c) : const Color(0xffff74b6), 0.9,
            minZoom: 6.0),
        'paris-stations': PointStyle(
            light ? const Color(0xffc2255c) : const Color(0xffff74b6), 0.9,
            minZoom: 26.0),
        'lgv-stations': PointStyle(
            light ? const Color(0xff5f3dc4) : const Color(0xffb197fc), 1.3,
            minZoom: 5.0),
      },
      {
        'grandes-villes': -1,
        'chefs-lieux': 3,
        'villes': 7,
        'lgv-stations': 5,
        'paris-stations': 30,
      },
      Rect.fromLTRB((2.30 - 6.0) * 0.6918, 51.85, (2.30 + 6.0) * 0.6918, 41.35),
    );

/* frames of the overseas territories: west longitude, north latitude,
   width, height */
const double _c46 = 0.6918;
const overseasFrames = <String, Rect>{
  'Guadeloupe': Rect.fromLTRB(
      (61.51 - 0.7) * _c46, 16.18 + 0.7, (61.51 + 0.7) * _c46, 16.18 - 0.7),
  'Martinique': Rect.fromLTRB(
      (61.02 - 0.5) * _c46, 14.64 + 0.5, (61.02 + 0.5) * _c46, 14.64 - 0.5),
  'Guyane': Rect.fromLTRB(
      (53.2 - 2.5) * _c46, 4.0 + 2.5, (53.2 + 2.5) * _c46, 4.0 - 2.5),
  'La Réunion': Rect.fromLTRB(
      (55.5 - 0.8) * _c46, -21.05 + 0.8, (55.5 + 0.8) * _c46, -21.05 - 0.8),
  'Mayotte': Rect.fromLTRB(
      (45.16 - 0.5) * _c46, -12.78 + 0.5, (45.16 + 0.5) * _c46, -12.78 - 0.5),
};

/* European Union: same units as France */
MapSettings unionSettings(bool light) => MapSettings(
      {
        'membres': StrokeStyle(
            light ? const Color(0xff495057) : const Color(0xffadb5bd), 0.5,
            closes: true),
        'autres': StrokeStyle(
            light ? const Color(0xff495057) : const Color(0xffadb5bd), 0.5,
            fill: light ? const Color(0x336b705c) : const Color(0x3394a396),
            closes: true),
        'hors-ue': StrokeStyle(
            light ? const Color(0xff868e96) : const Color(0xff6c757d), 0.4,
            fill: light ? const Color(0x14adb5bd) : const Color(0x14349db4),
            closes: true),
        'hors-ue-2': StrokeStyle(
            light ? const Color(0xff868e96) : const Color(0xff6c757d), 0.4,
            fill: light ? const Color(0x14adb5bd) : const Color(0x14349db4),
            closes: true),
        'hors-ue-3': StrokeStyle(
            light ? const Color(0xff868e96) : const Color(0xff6c757d), 0.4,
            fill: light ? const Color(0x14adb5bd) : const Color(0x14349db4),
            closes: true),
        'zee': StrokeStyle(const Color(0x00000000), 0,
            fill: light ? const Color(0x221c7ed6) : const Color(0x22191970)),
        'fleuves': StrokeStyle(
            light ? const Color(0xff1971c2) : const Color(0xff74c0fc), 0.7),
        'grands-fleuves': StrokeStyle(
            light ? const Color(0xff1971c2) : const Color(0xff74c0fc), 1.0),
        'eroutes': StrokeStyle(
            light ? const Color(0xff2f9e44) : const Color(0xff69db7c), 1.4,
            fill: null),
        'routes-voisins-brutes': StrokeStyle(
            light ? const Color(0x88a8891c) : const Color(0x88d4b83a), 0.5),
        'lgv': StrokeStyle(
            light ? const Color(0xff6741d9) : const Color(0xff9775fa), 1.4,
            dashes: [4.0, 2.5]),
      },
      {
        'capitales': PointStyle(
            light ? const Color(0xffc92a2a) : const Color(0xffff8787), 2.0,
            minZoom: -1),
        'villes': PointStyle(
            light ? const Color(0xff212529) : const Color(0xfff1f3f5), 1.2,
            minZoom: 3.0),
        'lgv-stations': PointStyle(
            light ? const Color(0xff5f3dc4) : const Color(0xffb197fc), 1.3,
            minZoom: 5.0),
      },
      {
        'capitales': -1,
        'villes': 6,
        'lgv-stations': 5,
      },
      Rect.fromLTRB((15.0 - 23.0) * 0.6918, 67.0, (15.0 + 23.0) * 0.6918, 35.0),
    );

/* ---------------- the painter ---------------- */

class MapPainter extends CustomPainter {
  final String map;
  final Map<String, db.GeoLayer> layers;
  final Map<String, List<db.NamedPoint>> points;
  final MapSettings settings;
  final TransformationController transformation;
  final Color textColor;
  final DateTime worldTime; // time of the night zone
  final bool light;
  final WorldStyle? worldStyle; // style of the dialog, ocean by default
  final bool worldNight; // night zone lit or unlit
  final bool worldSun; // the subsolar spot
  final bool worldGrid; // equator, tropics and polar circles
  final bool worldTz; // the time zone borders
  final bool worldEqualEarth; // Equal Earth or flat equirectangular
  final Map<String, String>
      worldConflicts; // the choices of the disputed borders menu
  final bool worldBorders; // solid border stroke lit or unlit
  final double center; // center meridian, like the dialog of the web

  MapPainter(this.map, this.layers, this.points, this.settings,
      this.transformation, this.textColor, this.worldTime, this.light,
      {this.worldStyle,
      this.worldNight = true,
      this.worldSun = false,
      this.worldGrid = false,
      this.worldTz = false,
      this.worldEqualEarth = true,
      this.worldConflicts = const <String, String>{},
      this.worldBorders = true,
      this.center = 0})
      : super(repaint: transformation);

  /* half width of the world plane: Equal Earth keeps its oval, the
     flat equirectangular mode of the web spans twice as wide */
  late final double _aspect = settings.bounds.width / 2;

  @override
  bool shouldRepaint(MapPainter old) =>
      old.map != map ||
      old.worldTime != worldTime ||
      old.light != light ||
      old.worldStyle != worldStyle ||
      old.worldNight != worldNight ||
      old.worldSun != worldSun ||
      old.worldGrid != worldGrid ||
      old.worldTz != worldTz ||
      old.worldEqualEarth != worldEqualEarth ||
      old.worldBorders != worldBorders ||
      old.center != center ||
      old.layers.length != layers.length ||
      old.points.length != points.length ||
      !_mapEquals(old.worldConflicts, worldConflicts);

  static bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }

  /* the recentered longitude: the center picks the middle meridian,
     the centered longitude equals the real longitude minus this
     meridian */
  double _recentered(double lon) => ((lon - center + 540) % 360) - 180;

  /* the plane of the world from an ALREADY recentered longitude. The
     pieces of ringClip, the graticule and the time zones arrive in the
     window of the center ( center - 180 .. center + 180 ): subtracting
     the center gives the recentered longitude directly. Wrapping that
     longitude again folded the two edge meridians onto the same one:
     every piece touching an edge bent across the map, whole bands
     inverted their colours and the equator collapsed to a point */
  Offset _worldPlane(double r, double lat) {
    if (worldEqualEarth) {
      final p = ee(lat, r);
      return Offset(p.dx * eeAspect, p.dy);
    }
    return Offset(r / 180 * _aspect, lat / 90);
  }

  /* screen position of a point given in the window of the center */
  Offset _worldScreen(
      double lon, double lat, Offset Function(double, double) toPlane) {
    final p = _worldPlane(lon - center, lat);
    return toPlane(p.dx, p.dy);
  }

  /* screen position of a point of the database: raw longitude, wrapped
     once into the window of the center, then projected */
  Offset _toScreen(
      double x, double y, Offset Function(double, double) toPlane) {
    if (map != 'monde') return toPlane(x, y);
    final p = _worldPlane(_recentered(x), y);
    return toPlane(p.dx, p.dy);
  }

  /* position in the plane ( database units, without screen scale ) */
  Offset _toPlane(double x, double y) {
    if (map != 'monde') return Offset(x, y);
    return _worldPlane(_recentered(x), y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final b = settings.bounds;
    final scale = math.min(size.width / b.width, size.height / -b.height);
    final dx = (size.width - b.width * scale) / 2 - b.left * scale;
    final dy = (size.height + b.height * scale) / 2 + b.top * scale;
    /* the plane y rises, the screen y falls */
    Offset toPlane(double x, double y) =>
        Offset(dx + x * scale, dy - y * scale);
    final m = transformation.value;
    final zoom = m.getMaxScaleOnAxis();

    final style = worldStyle ?? worldStyles['ocean']!;
    /* the gradient background of the world, only inside the rectangle of
       the map; the outline that tells the globe from the screen
       background is drawn at the end of paint, above everything */
    if (map == 'monde') {
      worldBackground(
          canvas,
          Rect.fromPoints(
              toPlane(-_aspect, 1), toPlane(_aspect, -1)),
          style);
    }

    /* filled outlines first */
    for (final e in settings.layers.entries) {
      final layer = layers[e.key];
      if (layer == null) continue;
      final st = e.value;
      if (e.key == 'membres') {
        /* one pastel tint per member state, like the web */
        for (final f in layer.features) {
          final p = Path();
          _addFeatureToPath(p, f, toPlane, close: true);
          canvas.drawPath(
              p, Paint()..color = euPalette[f.label] ?? defaultEuTint);
        }
        continue;
      }
      if (st.fill == null) continue;
      final p = Path();
      if (map == 'monde') {
        /* recentering: the ring cut at the seam meridian then comes back
           through the other edge, no more inverted colour bands; this
           is the wmRingClip of the web, ported in world_map.dart */
        for (final f in layer.features) {
          for (final piece in ringClip(f.points, center)) {
            for (var i = 0; i + 1 < piece.length; i += 2) {
              final q = _worldScreen(piece[i], piece[i + 1], toPlane);
              if (i == 0) {
                p.moveTo(q.dx, q.dy);
              } else {
                p.lineTo(q.dx, q.dy);
              }
            }
            p.close();
          }
        }
      } else {
        for (final f in layer.features) {
          _addFeatureToPath(p, f, toPlane, close: true);
        }
      }
      canvas.drawPath(p, Paint()..color = st.fill!);
    }
    /* strokes on top: the width and the dashes are counter-scaled by
       the zoom, they keep a constant on-screen size */
    /* the contested borders chosen in the menu: the solid stroke skips
       the boxes of the taken views, the erased borders come back as
       dotted overlays ( WM_DISPUTED of the web ) */
    final disputed = map == 'monde' ? disputedState(worldConflicts) : null;
    for (final e in settings.layers.entries) {
      final layer = layers[e.key];
      if (layer == null) continue;
      final st = e.value;
      if (st.color.alpha == 0 && st.width == 0) continue;
      /* the land stays when the borders are switched off: only the
         stroke of the country borders follows the switch, the fill of
         the continents comes from the same layer of the database */
      if (map == 'monde' && e.key == 'frontieres' && !worldBorders) {
        continue;
      }
      final p = Path();
      if (map == 'monde') {
        for (final f in layer.features) {
          for (final piece in ringClip(f.points, center)) {
            /* the closing edges along a seam meridian are not stroked
               ( wmStrokeClipped ), the segments inside a skip box of
               the disputed menu are not stroked either */
            final edgeW = center - 180.0, edgeE = center + 180.0;
            var pen = false;
            final n = piece.length ~/ 2;
            for (var i = 0; i < n; i++) {
              final x1 = piece[2 * i], y1 = piece[2 * i + 1];
              final jn = (2 * i + 2) % piece.length;
              final x2 = piece[jn], y2 = piece[jn + 1];
              if ((x1 - x2).abs() < 1e-9 &&
                  ((x1 - edgeW).abs() < 1e-9 ||
                      (x1 - edgeE).abs() < 1e-9)) {
                pen = false;
                continue;
              }
              if (disputed != null &&
                  e.key == 'frontieres' &&
                  disputedSkip(disputed.skipBoxes, x1, y1, x2, y2)) {
                pen = false;
                continue;
              }
              final q1 = _worldScreen(x1, y1, toPlane);
              final q2 = _worldScreen(x2, y2, toPlane);
              if (pen) {
                p.lineTo(q2.dx, q2.dy);
              } else {
                p.moveTo(q1.dx, q1.dy);
                p.lineTo(q2.dx, q2.dy);
                pen = true;
              }
            }
          }
        }
      } else {
        for (final f in layer.features) {
          _addFeatureToPath(p, f, toPlane, close: st.closes);
        }
      }
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..color = st.color
        ..strokeWidth = st.width / zoom
        ..isAntiAlias = true;
      if (st.dashes == null) {
        canvas.drawPath(p, paint);
      } else {
        for (final piece in p.computeMetrics()) {
          double moved = 0;
          final total = piece.length;
          final motif = st.dashes!;
          var k = 0;
          while (moved < total) {
            final step = motif[k % motif.length] / zoom;
            final end = math.min(moved + step, total);
            canvas.drawPath(piece.extractPath(moved, end), paint);
            moved = end + motif[(k + 1) % motif.length] / zoom;
            k += 2;
          }
        }
      }
    }
    if (map == 'monde') {
      /* the borders erased by a taken view come back as dotted
         overlays, the colour of the ordinary border */
      if (disputed != null && disputed.dotted.isNotEmpty) {
        drawDisputedDotted(
            canvas,
            (lon, lat) => _worldScreen(lon, lat, toPlane),
            style.border,
            disputed.dotted,
            center,
            1.0 / zoom);
      }
      /* equator, tropics and polar circles */
      if (worldGrid) {
        drawGraticule(
            canvas,
            (lon, lat) => _worldScreen(lon, lat, toPlane),
            style,
            1.0 / zoom,
            center);
      }
      /* the Natural Earth time zone borders, dashed */
      if (worldTz) {
        drawTimeZones(
            canvas,
            (lon, lat) => _worldScreen(lon, lat, toPlane),
            style,
            center,
            1.0 / zoom);
      }
      /* night zone of the world, in its own file */
      if (worldNight) {
        drawNightZone(canvas, toPlane, worldTime, style, center,
            aspect: _aspect, equalEarth: worldEqualEarth);
      }
    }
    /* points and labels: radii and texts counter-scaled, constant size
       on screen whatever the zoom; the labels never overlap, every
       placed one keeps its place */
    final inverseScale = 1.0 / zoom;
    final placed = <Rect>[];
    for (final e in settings.points.entries) {
      final list = points[e.key];
      if (list == null) continue;
      final st = e.value;
      final minZoom = st.minZoom ?? 0;
      if (zoom < minZoom) continue;
      final paint = Paint()..color = st.color;
      for (final pt in list) {
        final pos = _toScreen(pt.x, pt.y, toPlane);
        if (pos.dx < -60 ||
            pos.dy < -60 ||
            pos.dx > size.width + 60 ||
            pos.dy > size.height + 60) {
          continue;
        }
        canvas.drawCircle(pos, st.radius * inverseScale, paint);
      }
      final labelZoom = settings.labelsMinZoom[e.key];
      if (labelZoom != null && zoom >= labelZoom) {
        for (final pt in list) {
          _label(canvas, pt.name, _toScreen(pt.x, pt.y, toPlane),
              offset: (st.radius + 2) * inverseScale,
              scale: inverseScale,
              placed: placed);
        }
      }
    }
    /* road shields of the Union at high zooms */
    if (map == 'union' && zoom > 15) {
      final shields = <String, List<Color>>{
        'refs-aut': [const Color(0xffd0141a), Colors.white],
        'refs-rn': [const Color(0xffd0141a), Colors.white],
        'refs-rd': [const Color(0xffe8c220), Colors.black],
        'refs-er': [const Color(0xff1a8f3c), Colors.white],
      };
      for (final e in shields.entries) {
        final list = points[e.key];
        if (list == null) continue;
        for (final pt in list) {
          _badgeLabel(canvas, pt.name, _toScreen(pt.x, pt.y, toPlane),
              background: e.value[0],
              text: e.value[1],
              scale: inverseScale);
        }
      }
    }
    /* the subsolar spot, above the cities, under the outline */
    if (map == 'monde' && worldSun) {
      drawSunSpot(
          canvas,
          (lon, lat) => _worldScreen(lon, lat, toPlane),
          worldTime,
          center,
          1.0 / zoom);
    }
    /* the outline of the globe, above everything: it marks the edges of
       the world map and tells it from the screen background */
    if (map == 'monde') {
      worldOutline(
          canvas,
          Rect.fromPoints(
              toPlane(-_aspect, 1), toPlane(_aspect, -1)),
          1.0 / zoom,
          style);
    }
  }

  void _addFeatureToPath(
      Path p, db.GeoFeature f, Offset Function(double, double) v,
      {bool close = false, double threshold = 1.5}) {
    final pts = f.points;
    if (pts.isEmpty) return;
    Offset? lastPlane;
    var first = true;
    for (var i = 0; i + 1 < pts.length; i += 2) {
      /* the jump is measured in the plane, not in pixels: at high zoom
         every legitimate segment becomes long on screen */
      final plane = _toPlane(pts[i], pts[i + 1]);
      final pos = _toScreen(pts[i], pts[i + 1], v);
      /* a sudden jump between two neighbouring points betrays the
         crossing of the antimeridian ( world map ): the segment drew a
         straight line across the whole projection, as a horizontal
         bar; a new sub-path starts instead */
      if (lastPlane != null &&
          (plane.dx - lastPlane.dx) * (plane.dx - lastPlane.dx) +
                  (plane.dy - lastPlane.dy) * (plane.dy - lastPlane.dy) >
              threshold * threshold) {
        first = true;
      }
      lastPlane = plane;
      if (first) {
        p.moveTo(pos.dx, pos.dy);
        first = false;
      } else {
        p.lineTo(pos.dx, pos.dy);
      }
    }
    /* the closing is drawn only for polygon layers: on an open polyline
       ( river, road ), close() drew a straight chord that appeared as a
       bar when zoomed */
    if (close) p.close();
  }

  bool _label(Canvas canvas, String text, Offset pos,
      {double offset = 3, double scale = 1, List<Rect>? placed}) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              fontSize: 10 * scale,
              color: textColor,
              backgroundColor:
                  light ? const Color(0x66000000) : const Color(0x66ffffff))),
      textDirection: TextDirection.ltr,
    )..layout();
    /* a placed label never covers the already drawn ones: when zoomed
       the dense cities overlapped and became unreadable */
    final rect = Rect.fromLTRB(
        pos.dx + offset,
        pos.dy - tp.height / 2,
        pos.dx + offset + tp.width,
        pos.dy + tp.height / 2);
    if (placed != null) {
      for (final r in placed) {
        if (r.overlaps(rect.inflate(scale))) return false;
      }
      placed.add(rect);
    }
    tp.paint(canvas, pos + Offset(offset, -tp.height / 2));
    return true;
  }

  void _badgeLabel(Canvas canvas, String caption, Offset pos,
      {required Color background,
      Color text = const Color(0xffffffff),
      double scale = 1}) {
    final tp = TextPainter(
      text: TextSpan(
          text: caption,
          style: TextStyle(
              fontSize: 9 * scale,
              fontWeight: FontWeight.w700,
              color: text,
              letterSpacing: 0.5 * scale)),
      textDirection: TextDirection.ltr,
    )..layout();
    final rect = Rect.fromCenter(
        center: pos,
        width: tp.width + 8 * scale,
        height: tp.height + 4 * scale);
    final radius = Radius.circular(rect.height / 2);
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, radius), Paint()..color = background);
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, radius),
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.white
          ..strokeWidth = scale);
    tp.paint(canvas, rect.topLeft + Offset(4 * scale, 2 * scale));
  }
}

/* ---------------- the screen of a map ---------------- */

class MapScreen extends StatefulWidget {
  final String map;
  const MapScreen(this.map, {super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _transformation = TransformationController();
  Map<String, db.GeoLayer>? _layers;
  Map<String, List<db.NamedPoint>>? _points;
  DateTime _time = DateTime.now();
  String? _frame; // chosen overseas frame
  Map<String, bool> _groups = {}; // visible layers, settings dialog
  String _worldStyle = 'ocean'; // style of the world map
  double _worldCenter = 0; // center meridian of the world map
  Set<String> _hiddenCities = {}; // hidden marked cities of the world
  Map<String, String> _conflicts = {}; // choices of the disputed menu
  Timer? _ticker; // keeps the clock of the world on the current time
  bool _pinnedTime = false; // the user chose an other instant

  bool get _equalEarth => _groups['equal-earth'] ?? true;

  static const _layerNames = <String, List<String>>{
    'france': [
      'departements',
      'contour',
      'zee',
      'fleuves',
      'departementales',
      'nationales',
      'autoroutes',
      'lgv',
      'paris',
      'villes-transports'
    ],
    'union': [
      'hors-ue',
      'hors-ue-2',
      'hors-ue-3',
      'autres',
      'membres',
      'zee',
      'fleuves',
      'grands-fleuves',
      'routes-voisins-brutes',
      'eroutes',
      'lgv'
    ],
    'monde': worldLayers,
  };
  static const _pointNames = <String, List<String>>{
    'france': [
      'grandes-villes',
      'chefs-lieux',
      'villes',
      'lgv-stations',
      'stations',
      'paris-stations'
    ],
    'union': [
      'capitales',
      'villes',
      'lgv-stations',
      'refs-aut',
      'refs-rn',
      'refs-rd',
      'refs-er'
    ],
    'monde': worldPoints,
  };

  @override
  void initState() {
    super.initState();
    _load();
    /* the clocks of the world follow the current time, like the web;
       they stop as soon as the user picks an other instant */
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_pinnedTime || !mounted) return;
      setState(() => _time = DateTime.now());
    });
  }

  Future<void> _load() async {
    final layers = <String, db.GeoLayer>{};
    for (final c in _layerNames[widget.map] ?? const <String>[]) {
      layers[c] = await db.layer(widget.map, c);
    }
    final pts = <String, List<db.NamedPoint>>{};
    for (final c in _pointNames[widget.map] ?? const <String>[]) {
      pts[c] = await db.points(widget.map, c);
    }
    final groups = await readVisibility(widget.map);
    var style = _worldStyle;
    var center = _worldCenter;
    var hiddenCities = _hiddenCities;
    var conflicts = _conflicts;
    if (widget.map == 'monde') {
      style = await readWorldStyle();
      center = await readWorldCenter();
      hiddenCities = await readHiddenCities();
      conflicts = await readDisputed();
      /* the marked cities of the world come from the web list
         ( WM_CITYLIST, 500 cities ), not from the database: the layer
         of the base held the European list by mistake */
      pts['villes'] = (worldCities.toList()
            ..sort((a, b) {
              final byCountry = a.country.compareTo(b.country);
              if (byCountry != 0) return byCountry;
              return a.name.compareTo(b.name);
            }))
          .map((c) => db.NamedPoint(c.name, c.lon, c.lat, c.cc))
          .toList();
    }
    if (mounted) {
      setState(() {
        _layers = layers;
        _points = pts;
        _groups = groups;
        _worldStyle = style;
        _worldCenter = center;
        _hiddenCities = hiddenCities;
        _conflicts = conflicts;
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _transformation.dispose();
    super.dispose();
  }

  /* tooltip: the closest city, otherwise the polygon under the finger */
  Future<void> _handleTap(Offset local, Size size, bool light) async {
    final settings = _settings(light);
    final b = settings.bounds;
    final scale = math.min(size.width / b.width, size.height / -b.height);
    final dx = (size.width - b.width * scale) / 2 - b.left * scale;
    final dy = (size.height + b.height * scale) / 2 + b.top * scale;
    final inverse = (_transformation.value.clone()..invert())
        .transform(Vector4(local.dx, local.dy, 0, 1));
    /* coordinates of the touched plane */
    final px = (inverse.x - dx) / scale;
    final py = (dy - inverse.y) / scale;
    String? text;
    if (widget.map == 'monde') {
      final cities = _points?['villes'] ?? const <db.NamedPoint>[];
      text = worldTooltip(px, py, cities, 20 * 20 / (scale * scale),
          _worldCenter,
          aspect: settings.bounds.width / 2, equalEarth: _equalEarth);
    } else {
      /* closest city within 14 px */
      for (final e in settings.points.entries) {
        final list = _points?[e.key];
        if (list == null) continue;
        for (final v in list) {
          final dd = (v.x - px) * (v.x - px) + (v.y - py) * (v.y - py);
          if (dd * scale * scale < 14 * 14) {
            text = v.name + (v.info.isEmpty ? '' : ' · ${v.info}');
            break;
          }
        }
        if (text != null) break;
      }
      if (text == null) {
        /* polygon of the department or of the country under the finger */
        final layer =
            _layers?[widget.map == 'france' ? 'departements' : 'membres'];
        if (layer != null) {
          for (final f in layer.features) {
            if (!_pointInPolygon(px, py, f.points)) continue;
            if (widget.map == 'france') {
              final d = departments[f.label];
              text = d == null
                  ? f.label
                  : '${f.label} · ${d[0]}'
                      ' (${regionNames[d[1]] ?? d[1]})';
            } else {
              text = '${f.label} · ${euCountryNames[f.label] ?? ''}';
            }
            break;
          }
        }
      }
    }
    if (!mounted) return;
    if (text == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          duration: const Duration(seconds: 3),
          content: Text(text, style: const TextStyle(fontSize: 13))));
  }

  /* point in a polygon: classic ray casting */
  bool _pointInPolygon(double px, double py, Float32List pts) {
    var inside = false;
    var j = 0;
    for (var i = 0; i + 1 < pts.length; i += 2) {
      final xi = pts[i], yi = pts[i + 1];
      final xj = pts[j], yj = pts[j + 1];
      if (((yi > py) != (yj > py)) &&
          (px < (xj - xi) * (py - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
  }

  MapSettings _settings(bool light) {
    final r = widget.map == 'france'
        ? franceSettings(light)
        : widget.map == 'union'
            ? unionSettings(light)
            : worldSettings(light, worldStyles[_worldStyle], _equalEarth);
    if (widget.map == 'france' &&
        _frame != null &&
        overseasFrames.containsKey(_frame)) {
      final c = overseasFrames[_frame]!;
      return MapSettings(r.layers, r.points, r.labelsMinZoom, c);
    }
    return r;
  }

  /* only the visible layers and points: the settings dialog hides a
     whole group, the map redraws */
  Map<String, db.GeoLayer> _visibleLayers() {
    final m = <String, db.GeoLayer>{};
    _layers?.forEach((key, layer) {
      if (groupVisible(widget.map, key, _groups)) m[key] = layer;
    });
    return m;
  }

  Map<String, List<db.NamedPoint>> _visiblePoints() {
    final m = <String, List<db.NamedPoint>>{};
    _points?.forEach((key, list) {
      if (groupVisible(widget.map, key, _groups)) m[key] = list;
    });
    if (widget.map == 'monde' && m.containsKey('villes')) {
      m['villes'] = m['villes']!
          .where((v) => !_hiddenCities.contains(v.name))
          .toList();
    }
    return m;
  }

  Widget _settingsButton() => IconButton(
        tooltip: 'Réglages de la carte',
        icon: const Icon(Icons.tune),
        onPressed: _openSettings,
      );

  /* the settings dialog of the map, like on the web: every switch
     lights or dims a group, the world picks its style; every change
     persists at once in the preferences */
  Future<void> _openSettings() async {
    await mapSettingsDialog(
        context, widget.map, _groups, _worldStyle, _worldCenter, _conflicts,
        onChanged: (group, value) {
      writeVisibility(widget.map, group, value);
      setState(() => _groups[group] = value);
    }, onStyleChanged: (style) {
      writeWorldStyle(style);
      setState(() => _worldStyle = style);
    }, onCenterChanged: (center) {
      writeWorldCenter(center);
      setState(() => _worldCenter = center);
    }, onConflictsChanged: (conflicts) {
      writeDisputed(conflicts);
      setState(() => _conflicts = {...conflicts});
    }, onPickCities: () async {
      final cities = _points?['villes'] ?? const <db.NamedPoint>[];
      await worldCitiesDialog(context, cities.map((v) => v.name).toList(),
          _hiddenCities, (updated) {
        writeHiddenCities(updated);
        setState(() => _hiddenCities = {...updated});
      });
    });
  }

  /* the clocks of the marked cities at the chosen instant, like the
     web table: the visible cities sorted west to east then north to
     south, the real IANA zone of each city, the longitude estimate as
     a fallback marked with a tilde */
  List<Widget> _cityClocks() {
    final cities = (_visiblePoints()['villes'] ?? const <db.NamedPoint>[])
        .toList()
      ..sort((a, b) {
        final ra = ((a.x - _worldCenter + 540) % 360) - 180;
        final rb = ((b.x - _worldCenter + 540) % 360) - 180;
        if ((ra - rb).abs() > 1e-9) return ra.compareTo(rb);
        return b.y.compareTo(a.y);
      });
    final nameColor =
        Theme.of(context).textTheme.bodySmall?.color ?? const Color(0xff495057);
    return [
      for (final v in cities)
        () {
          final c = cityClock(v.name, v.info, v.x, _time);
          final hh = c.time.hour.toString().padLeft(2, '0');
          final mm = c.time.minute.toString().padLeft(2, '0');
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(v.name,
                  style: TextStyle(fontSize: 11, color: nameColor)),
              Text('${c.estimated ? '~' : ''}$hh:$mm',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              Text(gmtLabel(c.offset),
                  style: TextStyle(fontSize: 11, color: nameColor)),
            ],
          );
        }()
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_layers == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final light = Theme.of(context).brightness == Brightness.light;
    final settings = _settings(light);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (widget.map == 'france')
        Row(children: [
          Expanded(
              child: Wrap(spacing: 6, runSpacing: 4, children: [
            ChoiceChip(
              label: const Text('Métropole'),
              selected: _frame == null,
              onSelected: (_) => setState(() {
                _frame = null;
                _transformation.value = Matrix4.identity();
              }),
            ),
            for (final name in overseasFrames.keys)
              ChoiceChip(
                label: Text(name),
                selected: _frame == name,
                onSelected: (_) => setState(() {
                  _frame = name;
                  _transformation.value = Matrix4.identity();
                }),
              ),
          ])),
          _settingsButton(),
        ]),
      if (widget.map == 'france') const SizedBox(height: 8),
      if (widget.map == 'monde') ...[
        Row(children: [
          Expanded(
            child: Slider(
              value:
                  (_time.hour * 2 + (_time.minute >= 30 ? 1 : 0)).toDouble(),
              min: 0,
              max: 47,
              divisions: 48,
              label:
                  '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
              onChanged: (double v) {
                final base = DateTime(_time.year, _time.month, _time.day);
                setState(() {
                  _pinnedTime = true;
                  _time = base.add(Duration(minutes: (v * 30).round()));
                });
              },
            ),
          ),
          Text('${_time.day}/${_time.month} '
              '${_time.toString().substring(11, 16)}'),
          IconButton(
            tooltip: 'Date',
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              /* the calendar stays bounded to the current year, like
                 the half-hour slider it never leaves the clock */
              final picked = await showDatePicker(
                context: context,
                initialDate: _time,
                firstDate: DateTime(_time.year, 1, 1),
                lastDate: DateTime(_time.year, 12, 31),
              );
              if (picked == null) return;
              setState(() {
                _pinnedTime = true;
                _time = DateTime(picked.year, picked.month, picked.day,
                    _time.hour, _time.minute);
              });
            },
          ),
          IconButton(
            tooltip: 'Maintenant',
            icon: const Icon(Icons.restore),
            onPressed: () => setState(() {
              _pinnedTime = false;
              _time = DateTime.now();
            }),
          ),
          _settingsButton(),
        ]),
        if ((_groups['horloges'] ?? false))
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
            child: Wrap(
              spacing: 10,
              runSpacing: 4,
              children: [for (final cell in _cityClocks()) cell],
            ),
          ),
      ],
      if (widget.map == 'union')
        Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [_settingsButton()]),
      Expanded(
        child: LayoutBuilder(builder: (context, constraints) {
          final h = constraints.maxWidth /
              (widget.map == 'monde' ? (_equalEarth ? eeAspect : 2.0) : 1.6);
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: InteractiveViewer(
              transformationController: _transformation,
              minScale: 0.8,
              maxScale: 200,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => _handleTap(
                    d.localPosition, Size(constraints.maxWidth, h), light),
                child: CustomPaint(
                  size: Size(constraints.maxWidth, h),
                  painter: MapPainter(
                      widget.map,
                      /* the world keeps its continents when the borders
                         are switched off: the layer always reaches the
                         painter, the stroke alone follows the switch */
                      widget.map == 'monde'
                          ? (_layers ?? const <String, db.GeoLayer>{})
                          : _visibleLayers(),
                      _visiblePoints(),
                      settings,
                      _transformation,
                      light ? const Color(0xff212529) : const Color(0xfff1f3f5),
                      _time,
                      light,
                      worldStyle: worldStyles[_worldStyle],
                      worldNight: _groups['nuit'] ?? true,
                      worldSun: _groups['soleil'] ?? true,
                      worldGrid: _groups['grille'] ?? true,
                      worldTz: _groups['fuseaux'] ?? true,
                      worldEqualEarth: _equalEarth,
                      worldConflicts: _conflicts,
                      worldBorders: _groups['frontieres'] ?? true,
                      center: _worldCenter),
                ),
              ),
            ),
          );
        }),
      ),
    ]);
  }
}