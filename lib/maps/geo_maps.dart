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

import '../database.dart' as db;
import '../l10n.dart' show translate;
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

/* one clipped piece of stroke with its bounds: at a high zoom only
   the pieces the screen touches come back into the drawn path */
class _StrokePiece {
  final Rect bounds;
  final Path path;
  const _StrokePiece(this.bounds, this.path);
}

/* the projected geometry of a map, built once then reused at every
   frame: the fills, the strokes and the member tints as ready Paths */
class _MapGeometry {
  final Map<String, Path> fills = <String, Path>{};
  final Map<String, Path> strokes = <String, Path>{};
  final Map<String, List<Path>> tints = <String, List<Path>>{};
  /* the strokes cut in pieces with their bounds, for the culling of
     the off-screen rings at a high zoom */
  final Map<String, List<_StrokePiece>> strokePieces =
      <String, List<_StrokePiece>>{};
  final Map<String, Rect> strokeBounds = <String, Rect>{};
}

/* one single geometry stays cached: the Paths of a layer at the 1:10M
   precision own tens of megabytes, the previous map releases its own
   when the key changes */
_MapGeometry? _geometryCache;
String? _geometryCacheKey;

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

  /* the projected geometry, cached across the painter instances and
     across the frames: panning and zooming used to clip and reproject
     every vertex of every layer at each frame, which froze the
     navigation; only the inputs the geometry truly depends on rebuild
     it, the zoom and the time stay out */
  _MapGeometry _geometry(Size size, Offset Function(double, double) toPlane) {
    final b = settings.bounds;
    final keys = layers.keys.toList()..sort();
    final conflicts = worldConflicts.entries.toList()
      ..sort((a, c) => a.key.compareTo(c.key));
    final key = [
      map,
      center.toStringAsFixed(6),
      worldEqualEarth.toString(),
      size.width.toStringAsFixed(2),
      size.height.toStringAsFixed(2),
      b.left.toStringAsFixed(4),
      b.top.toStringAsFixed(4),
      b.right.toStringAsFixed(4),
      b.bottom.toStringAsFixed(4),
      keys.join(','),
      for (final c in conflicts) '${c.key}=${c.value}',
    ].join('|');
    final cached = _geometryCache;
    if (cached != null && _geometryCacheKey == key) return cached;

    final geo = _MapGeometry();
    final disputed = map == 'monde' ? disputedState(worldConflicts) : null;
    for (final e in settings.layers.entries) {
      final layer = layers[e.key];
      if (layer == null) continue;
      final st = e.value;
      /* the fill of the layer, closed subpaths of the clipped rings */
      if (map != 'monde' && e.key == 'membres') {
        /* one pastel tint per member state, like the web */
        geo.tints[e.key] = [
          for (final f in layer.features)
            () {
              final p = Path();
              _addFeatureToPath(p, f, toPlane, close: true);
              return p;
            }()
        ];
      } else if (st.fill != null) {
        final p = Path();
        if (map == 'monde') {
          /* recentering: the ring cut at the seam meridian then comes
             back through the other edge, no more inverted colour
             bands; this is the wmRingClip of the web, ported in
             world_map.dart */
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
        geo.fills[e.key] = p;
      }
      /* the stroke of the layer: every clipped piece with its bounds,
         plus the merged path of the whole layer; the width follows the
         zoom at the draw only */
      if (st.color.alpha == 0 && st.width == 0) continue;
      final merged = Path();
      final pieces = <_StrokePiece>[];
      if (map == 'monde') {
        for (final f in layer.features) {
          for (final piece in ringClip(f.points, center)) {
            /* the closing edges along a seam meridian are not stroked
               ( wmStrokeClipped ), the segments inside a skip box of
               the disputed menu are not stroked either */
            final edgeW = center - 180.0, edgeE = center + 180.0;
            var pen = false;
            final p = Path();
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
            if (p.getBounds().isEmpty) continue;
            pieces.add(_StrokePiece(p.getBounds(), p));
            merged.addPath(p, Offset.zero);
          }
        }
      } else {
        for (final f in layer.features) {
          final p = Path();
          _addFeatureToPath(p, f, toPlane, close: st.closes);
          if (p.getBounds().isEmpty) continue;
          pieces.add(_StrokePiece(p.getBounds(), p));
          merged.addPath(p, Offset.zero);
        }
      }
      geo.strokes[e.key] = merged;
      geo.strokeBounds[e.key] = merged.getBounds();
      geo.strokePieces[e.key] = pieces;
    }
    _geometryCache = geo;
    _geometryCacheKey = key;
    return geo;
  }

  /* the stroke of a layer, reduced to the pieces the screen touches:
     at a high zoom the off-screen rings no longer reach the raster,
     when everything shows the merged path draws as it is, without a
     copy */
  Path? _visibleStroke(String key, Rect visible) {
    final geo = _geometryCache!;
    final full = geo.strokes[key];
    final bounds = geo.strokeBounds[key];
    final pieces = geo.strokePieces[key];
    if (full == null || bounds == null || pieces == null) return null;
    final screen = visible.inflate(8);
    if (screen.left <= bounds.left &&
        screen.top <= bounds.top &&
        screen.right >= bounds.right &&
        screen.bottom >= bounds.bottom) {
      return full;
    }
    final p = Path();
    for (final piece in pieces) {
      if (piece.bounds.overlaps(screen)) p.addPath(piece.path, Offset.zero);
    }
    return p;
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

  /* the shape of the world map in screen coordinates: the Equal Earth
     oval sampled two degrees at a time along its edge ( the pole
     lines, then the two curved flank meridians ), the whole rounded
     rectangle in the flat mode, where nothing shows behind the map */
  Path _worldShape(Offset Function(double, double) toPlane) {
    final path = Path();
    if (!worldEqualEarth) {
      path.addRRect(RRect.fromRectAndRadius(
          Rect.fromPoints(toPlane(-_aspect, 1), toPlane(_aspect, -1)),
          const Radius.circular(12)));
      return path;
    }
    var first = true;
    void add(Offset p) {
      if (first) {
        path.moveTo(p.dx, p.dy);
        first = false;
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }

    for (var c = center - 180.0; c <= center + 180.0 + 1e-9; c += 2.0) {
      add(_worldScreen(c, 90, toPlane));
    }
    for (var la = 88.0; la >= -90.0; la -= 2.0) {
      add(_worldScreen(center + 180.0, la, toPlane));
    }
    for (var c = center + 180.0; c >= center - 180.0 - 1e-9; c -= 2.0) {
      add(_worldScreen(c, -90, toPlane));
    }
    for (var la = -88.0; la <= 90.0; la += 2.0) {
      add(_worldScreen(center - 180.0, la, toPlane));
    }
    path.close();
    return path;
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
    /* the part of the canvas the zoom shows, in the coordinates of the
       map: the off-screen strokes stay out of the drawn path at a
       high zoom, the chip machines raster only what the eye sees */
    final visible = MatrixUtils.transformRect(m, Offset.zero & size);

    final style = worldStyle ?? worldStyles['ocean']!;
    /* the rectangle behind the globe stays grey: in Equal Earth the
       four corners of the rectangle lie outside the oval, the ocean
       gradient only paints inside the shape of the map ( the outside
       of the web, here a plain grey that tells the globe from the
       page ); the outline is drawn at the end of paint, above
       everything */
    if (map == 'monde') {
      final rect =
          Rect.fromPoints(toPlane(-_aspect, 1), toPlane(_aspect, -1));
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(12)),
          Paint()
            ..color = light
                ? const Color(0xffe4e7ec)
                : const Color(0xff16181d));
      canvas.save();
      canvas.clipPath(_worldShape(toPlane));
      worldBackground(canvas, rect, style);
      canvas.restore();
    }

    /* the geometry comes from the cache, the paint alone stays here */
    final geo = _geometry(size, toPlane);
    /* filled outlines first */
    for (final e in settings.layers.entries) {
      final layer = layers[e.key];
      if (layer == null) continue;
      final st = e.value;
      if (map != 'monde' && e.key == 'membres') {
        /* one pastel tint per member state, like the web */
        final tinted = geo.tints[e.key] ?? const <Path>[];
        for (var i = 0; i < layer.features.length && i < tinted.length; i++) {
          canvas.drawPath(tinted[i],
              Paint()..color = euPalette[layer.features[i].label] ?? defaultEuTint);
        }
        continue;
      }
      if (st.fill == null) continue;
      final p = geo.fills[e.key];
      if (p == null) continue;
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
      final p = _visibleStroke(e.key, visible);
      if (p == null) continue;
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
      /* the rulers of the globe: the longitude along the top edge, the
         latitude along the left edge */
      _drawRulers(canvas, toPlane, inverseScale);
    }
  }

  /* the rulers of the world map: the longitude reads along the top
     edge, the latitude along the left edge; every tick sits where
     the projection puts its meridian at the equator and its parallel
     at the center meridian, the numbers keep their size whatever the
     zoom, like the labels of the cities */
  void _drawRulers(Canvas canvas,
      Offset Function(double, double) toPlane, double inverseScale) {
    final rect =
        Rect.fromPoints(toPlane(-_aspect, 1), toPlane(_aspect, -1));
    final rh = 16 * inverseScale; // height of the longitude strip
    final rw = 30 * inverseScale; // width of the latitude strip
    final bg = Paint()
      ..color =
          light ? const Color(0x14000000) : const Color(0x1fffffff);
    final stroke = Paint()
      ..color =
          light ? const Color(0x66000000) : const Color(0x77ffffff)
      ..strokeWidth = inverseScale
      ..style = PaintingStyle.stroke;
    /* the latitude strip starts under the longitude strip, the two
       never paint over each other */
    canvas.drawRect(
        Rect.fromLTWH(rect.left, rect.top, rect.width, rh), bg);
    canvas.drawRect(Rect.fromLTWH(rect.left, rect.top + rh, rw,
        rect.height - rh), bg);
    canvas.drawLine(Offset(rect.left, rect.top + rh),
        Offset(rect.right, rect.top + rh), stroke);
    canvas.drawLine(Offset(rect.left + rw, rect.top + rh),
        Offset(rect.left + rw, rect.bottom), stroke);
    /* the numbers of the rulers live in small texts, the color of the
       labels of the painter */
    void num(String s, Offset at, bool center) {
      final tp = TextPainter(
          text: TextSpan(
              text: s,
              style: TextStyle(
                  fontSize: 8.5 * inverseScale, color: textColor)),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas,
          center ? at.translate(-tp.width / 2, 0) : at);
    }

    /* the longitude: a tick every 15 degrees, a number every 30, at
       the screen x of the meridian on the equator */
    for (var lon = -180.0; lon < 180.0; lon += 15) {
      final px = _worldPlane(lon, 0).dx;
      final x = toPlane(px, 0).dx;
      canvas.drawLine(Offset(x, rect.top),
          Offset(x, rect.top + rh * 0.55), stroke);
      if (lon % 30 != 0) continue;
      /* the numbers of the far west hide under the latitude strip */
      if (x < rect.left + rw + 14 * inverseScale) continue;
      final real = ((lon + center + 540) % 360) - 180;
      num(real == 0 ? '0' : '${real.abs().round()}°${real > 0 ? 'E' : 'O'}',
          Offset(x, rect.top + 5.5 * inverseScale), true);
    }
    /* the latitude: a tick every 10 degrees, a number every 30, at
       the screen y of the parallel on the center meridian */
    for (var lat = -80.0; lat <= 80.0; lat += 10) {
      final py = worldEqualEarth ? ee(lat, 0).dy : lat / 90;
      final y = toPlane(0, py).dy;
      canvas.drawLine(Offset(rect.left, y),
          Offset(rect.left + rw * 0.55, y), stroke);
      if (lat % 30 != 0) continue;
      num(lat == 0 ? '0' : '${lat.abs().round()}°${lat > 0 ? 'N' : 'S'}',
          Offset(rect.left + rw * 0.62, y - 5 * inverseScale), false);
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

  /* the shaped labels, cached: shaping a text is one of the heaviest
     works of the painter, every city name used to re-shape at each
     frame; the font sizes round to half a pixel so a zoom sweeps a
     few buckets, and the cache empties itself when it grows too big */
  static final Map<String, TextPainter> _shaped = {};

  static void _rememberShaped(String key, TextPainter tp) {
    if (_shaped.length > 2000) _shaped.clear();
    _shaped[key] = tp;
  }

  TextPainter _shapedLabel(String text, double size) {
    final key = 'l|$text|${(size * 2).round()}|${textColor.value}';
    final cached = _shaped[key];
    if (cached != null) return cached;
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              fontSize: size,
              color: textColor,
              backgroundColor:
                  light ? const Color(0x66000000) : const Color(0x66ffffff))),
      textDirection: TextDirection.ltr,
    )..layout();
    _rememberShaped(key, tp);
    return tp;
  }

  TextPainter _shapedBadge(String caption, double size, Color color) {
    final key = 'b|$caption|${(size * 2).round()}|${color.value}';
    final cached = _shaped[key];
    if (cached != null) return cached;
    final tp = TextPainter(
      text: TextSpan(
          text: caption,
          style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5 * (size / 9))),
      textDirection: TextDirection.ltr,
    )..layout();
    _rememberShaped(key, tp);
    return tp;
  }

  bool _label(Canvas canvas, String text, Offset pos,
      {double offset = 3, double scale = 1, List<Rect>? placed}) {
    final tp = _shapedLabel(text, 10 * scale);
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
    final tp = _shapedBadge(caption, 9 * scale, text);
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

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
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
  final _tapKey = GlobalKey(); // the box of the map for the taps

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
    WidgetsBinding.instance.addObserver(this);
    _load();
    /* the clock of the world wakes exactly on the minute change of
       the user: the one-shot timer measures what separates now from
       the next boundary of the wall clock instead of counting a
       plain minute from the opening of the screen, the night zone
       switches when the clock of the user switches */
    _armMinute();
  }

  /* the minute of the world, only when something on the screen reads
     the current time: the night zone, the sun or the clocks of the
     marked cities; on the other maps and with everything switched off
     the machine sleeps, nothing wakes it for a redraw nobody sees */
  void _armMinute() {
    _ticker?.cancel();
    _ticker = null;
    if (widget.map != 'monde' || _pinnedTime) return;
    final needed = (_groups['nuit'] ?? true) ||
        (_groups['soleil'] ?? true) ||
        (_groups['horloges'] ?? false);
    if (!needed) return;
    final left =
        60000 - (DateTime.now().millisecondsSinceEpoch % 60000);
    _ticker = Timer(Duration(milliseconds: left), _onMinute);
  }

  void _onMinute() {
    if (!mounted) return;
    setState(() => _time = DateTime.now());
    _armMinute();
  }

  /* minimized pauses the map, a window unfocused but still on the
     screen keeps living: the observer reports the same states on
     Windows, macOS, Linux and Android, hidden or paused means
     minimized, inactive only means the window lost the focus */
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.map != 'monde') return;
    final asleep = state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused;
    if (asleep) {
      _ticker?.cancel();
      _ticker = null;
    } else {
      if (!_pinnedTime) {
        setState(() => _time = DateTime.now());
      }
      _armMinute();
    }
  }

  Future<void> _load() async {
    /* every layer and every point group loads at once: the decodings
       run side by side in their isolates instead of waiting for one
       another, the map opens several times faster and the CPU goes
       back to idle sooner */
    final layerNames = _layerNames[widget.map] ?? const <String>[];
    final pointNames = _pointNames[widget.map] ?? const <String>[];
    final loadedLayers = await Future.wait(
        [for (final c in layerNames) db.layer(widget.map, c)]);
    final loadedPoints = await Future.wait(
        [for (final c in pointNames) db.points(widget.map, c)]);
    final layers = <String, db.GeoLayer>{
      for (var i = 0; i < layerNames.length; i++) layerNames[i]: loadedLayers[i]
    };
    final pts = <String, List<db.NamedPoint>>{
      for (var i = 0; i < pointNames.length; i++) pointNames[i]: loadedPoints[i]
    };
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
        _armMinute();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideBubble();
    _ticker?.cancel();
    _transformation.dispose();
    super.dispose();
  }

  /* tooltip: the closest city, otherwise the polygon under the finger;
     the bubble floats above the pointer and follows the mouse like the
     tooltip of the web site, a tap pins it for three seconds */
  OverlayEntry? _bubble;
  Timer? _bubbleTimer;
  String? _bubbleText;
  Offset? _bubbleAt;
  bool _bubbleLight = true;

  void _hideBubble() {
    _bubbleTimer?.cancel();
    _bubbleTimer = null;
    /* the field empties before the removal: the dispose, a later timer
       or the exit of the mouse can all pass here, an entry removed
       twice crashed the overlay */
    final b = _bubble;
    _bubble = null;
    _bubbleText = null;
    b?.remove();
  }

  /* the text and the place live in the fields: the entry rebuilds at
     every move of the mouse, the bubble slides instead of blinking */
  void _showBubble(Offset global, String? text, bool light,
      {Duration? ttl}) {
    if (!mounted) return;
    _bubbleTimer?.cancel();
    _bubbleTimer = null;
    if (text == null) {
      _hideBubble();
      return;
    }
    final overlay = Overlay.of(context);
    final box = overlay.context.findRenderObject() as RenderBox;
    _bubbleAt = box.globalToLocal(global);
    _bubbleText = text;
    _bubbleLight = light;
    if (_bubble == null) {
      /* the colours of the painter: a dark bubble on the light theme,
         a light bubble on the dark theme, rounded corners and a
         discreet shadow like the tooltip of the web; the Material
         wraps the text, without it the overlay falls back on its
         default style and underlines every bubble twice in yellow */
      _bubble = OverlayEntry(
          builder: (ctx) => Positioned(
                left: _bubbleAt!.dx,
                top: _bubbleAt!.dy,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -1.2),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _bubbleLight
                            ? const Color(0xff212529)
                            : const Color(0xfff1f3f5),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 6,
                              offset: Offset(0, 2)),
                        ],
                      ),
                      child: Text(_bubbleText!,
                          style: TextStyle(
                              fontSize: 13,
                              color: _bubbleLight
                                  ? const Color(0xfff1f3f5)
                                  : const Color(0xff212529))),
                    ),
                  ),
                ),
              ));
      overlay.insert(_bubble!);
    } else {
      _bubble!.markNeedsBuild();
    }
    if (ttl != null) {
      _bubbleTimer = Timer(ttl, _hideBubble);
    }
  }

  /* the real box of the map: the InteractiveViewer forces the tight
     constraints of the area on its child, the painted map stands
     centered inside a taller box, the empty parts around it answer
     the pointer too; every conversion of the pointer reads this real
     box and its size, never the theoretical height of the map, the
     equator used to sit under the finger and the coordinates read
     the latitude of another ocean */
  RenderBox? _tapBox() {
    final box =
        _tapKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.size.isFinite) return null;
    return box;
  }

  /* the text of the bubble at a position of the map: the closest city
     or the polygon under the pointer, nothing over the empty parts */
  String? _infoAt(Offset? scene, Size size, bool light) {
    if (scene == null) return null;
    final settings = _settings(light);
    final b = settings.bounds;
    final scale = math.min(size.width / b.width, size.height / -b.height);
    final dx = (size.width - b.width * scale) / 2 - b.left * scale;
    final dy = (size.height + b.height * scale) / 2 + b.top * scale;
    final px = (scene.dx - dx) / scale;
    final py = (dy - scene.dy) / scale;
    String? text;
    final shown = _visiblePoints();
    if (widget.map == 'monde') {
      /* the bubble lives on the globe itself: the inversion of the
         Equal Earth oval used to read nonsense in its corners and a
         NaN under the map, the empty parts of the window and the
         grey margins stay silent now */
      if (_equalEarth) {
        final nx = px / eeAspect;
        if (nx.abs() > 1 || py.abs() > 1) return null;
        final inv = eeInv(nx, py);
        final edge = ee(inv[1], 180.0).dx;
        if (nx.abs() > edge) return null;
      } else if (px.abs() > 2 || py.abs() > 1) {
        return null;
      }
      final cities = shown['villes'] ?? const <db.NamedPoint>[];
      text = worldTooltip(px, py, cities, 20 * 20 / (scale * scale),
          _worldCenter,
          equalEarth: _equalEarth);
    } else {
      /* the closest city within 14 px: several markers can sit inside
         the radius, the nearest one wins, the first of the list used
         to answer before the true city; a hidden group stays silent */
      var best = 14.0 * 14.0;
      for (final e in shown.entries) {
        for (final v in e.value) {
          final dd = (v.x - px) * (v.x - px) + (v.y - py) * (v.y - py);
          if (dd * scale * scale < best) {
            best = dd * scale * scale;
            text = v.name + (v.info.isEmpty ? '' : ' · ${v.info}');
          }
        }
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
    return text;
  }

  /* a tap pins the bubble for three seconds */
  void _handleTap(Offset global, bool light) {
    final box = _tapBox();
    if (!mounted || box == null) return;
    _showBubble(global, _infoAt(box.globalToLocal(global), box.size, light),
        light,
        ttl: const Duration(seconds: 3));
  }

  /* the bubble follows the mouse like the tooltip of the web: the text
     recomputes under the pointer, nothing shows over the parts without
     information, leaving the map closes the bubble; a bubble pinned by
     a tap stays put until its timer ends */
  /* the type of the hover event lives in package:flutter/gestures,
     not exported by material.dart on every platform: the position
     arrives plain, without naming the event */
  void _handleHover(Offset global, bool light) {
    if (_bubbleTimer != null) return;
    final box = _tapBox();
    if (box == null) return;
    _showBubble(global, _infoAt(box.globalToLocal(global), box.size, light),
        light);
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
        tooltip: translate('reglages-carte'),
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
      /* a switched-on night, sun or clocks brings the minute back */
      _armMinute();
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
              label: Text(translate('metropole')),
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
                _armMinute();
              },
            ),
          ),
          /* the clock bar of the web: the half-hour slider, the time,
             the day one step back, the date alone, the day one step
             forward, the reset to now, the settings */
          Text(_time.toString().substring(11, 16)),
          IconButton(
            tooltip: translate('jour-avant'),
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() {
              _pinnedTime = true;
              _time = DateTime(_time.year, _time.month, _time.day - 1,
                  _time.hour, _time.minute);
              _armMinute();
            }),
          ),
          Text('${_time.day}/${_time.month}'),
          IconButton(
            tooltip: translate('jour-apres'),
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() {
              _pinnedTime = true;
              _time = DateTime(_time.year, _time.month, _time.day + 1,
                  _time.hour, _time.minute);
              _armMinute();
            }),
          ),
          IconButton(
            tooltip: translate('maintenant'),
            icon: const Icon(Icons.restore),
            onPressed: () => setState(() {
              _pinnedTime = false;
              _time = DateTime.now();
              _armMinute();
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
              child: MouseRegion(
                /* the bubble follows the mouse and closes when the
                   pointer leaves the map, like the tooltip of the web */
                onHover: (e) => _handleHover(e.position, light),
                onExit: (_) => _hideBubble(),
                child: GestureDetector(
                  key: _tapKey,
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) => _handleTap(d.globalPosition, light),
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
            ),
          );
        }),
      ),
    ]);
  }
}