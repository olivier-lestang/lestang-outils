/* The Equal Earth projection of the web ( js/monde/carte-monde.js ):
   the same coefficients, the same Newton inversion; plus the subsolar
   point and the night polygon for the world map day-night shading.
   SPDX-License-Identifier: MIT. */
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Offset;

const _rad = math.pi / 180.0;
const _eeA1 = 1.340264, _eeA2 = -0.081106, _eeA3 = 0.000893, _eeA4 = 0.003796;
const _eeM = 0.8660254037844386; // sqrt(3) / 2

double _eeCoef(double th) =>
    1 /
    (_eeM *
        (_eeA1 +
            3 * _eeA2 * th * th +
            math.pow(th, 6) * (7 * _eeA3 + 9 * _eeA4 * th * th)));

double _eeLat(double th) =>
    th *
        (_eeA1 + _eeA2 * th * th + math.pow(th, 6) * (_eeA3 + _eeA4 * th * th));

final double eeXmax = math.pi * _eeCoef(0);
final double eeYmax = _eeLat(math.pi / 3);

/* latitude and longitude in degrees to the normalized plane [-1..1] */
Offset ee(double lat, double lon) {
  final th = math.asin(_eeM * math.sin(lat * _rad));
  return Offset(
      lon * _rad * math.cos(th) * _eeCoef(th) / eeXmax, _eeLat(th) / eeYmax);
}

/* normalized plane to latitude and longitude in degrees ( Newton, like
   d3-geo ) */
List<double> eeInv(double nx, double ny) {
  var l = ny * eeYmax / _eeA1, l2 = l * l, l6 = l2 * l2 * l2, dl = 0.0;
  for (var i = 0; i < 12; i++) {
    final fy =
        l * (_eeA1 + _eeA2 * l2 + l6 * (_eeA3 + _eeA4 * l2)) - ny * eeYmax;
    final fpy = _eeA1 + 3 * _eeA2 * l2 + l6 * (7 * _eeA3 + 9 * _eeA4 * l2);
    dl = fy / fpy;
    l -= dl;
    l2 = l * l;
    l6 = l2 * l2 * l2;
    if (dl.abs() < 1e-12) break;
  }
  final lon = _eeM *
      nx *
      eeXmax *
      (_eeA1 + 3 * _eeA2 * l2 + l6 * (7 * _eeA3 + 9 * _eeA4 * l2)) /
      math.cos(l) /
      _rad;
  final lat = math.asin(math.sin(l) / _eeM) / _rad;
  return [lon, lat];
}

/* aspect ratio of the Equal Earth plane: 2.0546 to 1 */
const double eeAspect = 2.0546;

/* ---------------- subsolar point ( NOAA declination + equation of time ) ---------------- */

class SubsolarPoint {
  final double lat, lon;
  const SubsolarPoint(this.lat, this.lon);
}

SubsolarPoint subsolarPoint(DateTime utc) {
  final ms = utc.millisecondsSinceEpoch.toDouble();
  final jc = (ms / 86400000 + 2440587.5 - 2451545) / 36525;
  final meanLon = (280.46646 + jc * (36000.76983 + 0.0003032 * jc)) % 360;
  final anomaly = 357.52911 + jc * (35999.05029 - 0.0001537 * jc);
  final ecc = 0.016708634 - jc * (0.000042037 + 0.0000001267 * jc);
  final centerEq =
      math.sin(anomaly * _rad) * (1.914602 - jc * (0.004817 + 0.000014 * jc)) +
          math.sin(2 * anomaly * _rad) * (0.019993 - 0.000101 * jc) +
          math.sin(3 * anomaly * _rad) * 0.000289;
  final appLon = meanLon +
      centerEq -
      0.00569 -
      0.00478 * math.sin((125.04 - 1934.136 * jc) * _rad);
  final meanObl = 23 +
      (26 + ((21.448 - jc * (46.815 + jc * (0.00059 - jc * 0.001813))) / 60)) /
          60;
  final trueObl =
      meanObl + 0.00256 * math.cos((125.04 - 1934.136 * jc) * _rad);
  final decl =
      math.asin(math.sin(trueObl * _rad) * math.sin(appLon * _rad)) / _rad;
  final tanSq = math.tan(trueObl / 2 * _rad) * math.tan(trueObl / 2 * _rad);
  final eqTime = 4 *
      (tanSq * math.sin(2 * meanLon * _rad) -
          2 * ecc * math.sin(anomaly * _rad) +
          4 *
              ecc *
              tanSq *
              math.sin(anomaly * _rad) *
              math.cos(2 * meanLon * _rad) -
          0.5 * tanSq * tanSq * math.sin(4 * meanLon * _rad) -
          1.25 * ecc * ecc * math.sin(2 * anomaly * _rad)) /
      _rad;
  var lon = -(((ms / 3600000) % 24) + eqTime / 60 - 12) * 15;
  lon = ((lon + 540) % 360) - 180;
  return SubsolarPoint(decl, lon);
}

/* ---------------- night polygon ---------------- */

/* The vertices of the night polygon, in the normalized plane: the
   terminator curve then the closing through the night pole. The whole
   outline lives in the recentered frame: the centered longitude equals
   the real longitude minus the center meridian, the closing then follows
   the edges of the map whatever the chosen center. Around the equinoxes
   the near-zero declination makes the terminator almost vertical and
   elusive: the polygon draws it for a declination clamped to one degree,
   the deviation stays under two degrees of solar elevation a few hours
   per year. The painter only has to frame it and fill it. */
List<Offset> nightPolygon(SubsolarPoint sun,
    {double meridian = 0, bool equalEarth = true}) {
  final realSin = math.sin(sun.lat * _rad);
  final decl =
      realSin.abs() < 0.01745 ? (realSin < 0 ? -1.0 : 1.0) : sun.lat;
  final sinLat = math.sin(decl * _rad);
  final cosLat = math.cos(decl * _rad);
  Offset toPlane(double c, double lat) {
    var l = c % 360.0;
    if (l > 180) {
      l -= 360;
    } else if (l < -180) {
      l += 360;
    }
    /* the antimeridian: the centered longitude -180 stays on the west
       edge of the map; without this guard the first vertex jumped to the
       east edge, the outline crossed the map from end to end and the
       shaded area ended up inverted, day where night should be */
    if (l == 180 && c < 0) {
      l = -180;
    }
    /* the equirectangular fallback of the web ( wmER ): the same
       normalised plane, straight meridians */
    if (!equalEarth) return Offset(l / 180.0, lat / 90.0);
    return ee(lat, l);
  }

  final night = <Offset>[];
  final nightPole = sinLat < 0 ? 90.0 : -90.0;
  /* the terminator curve: near the equinoxes it becomes almost
     vertical, the latitude jumps by tens of degrees over two degrees of
     longitude; each steep segment is therefore subdivided by
     bisection, otherwise whole shreds of the wrong side of the limit
     were shaded near the equator */
  final h0 = meridian - sun.lon;
  double terminatorLat(double c) =>
      math.atan(-cosLat * math.cos((c + h0) * _rad) / sinLat) / _rad;

  void subdivide(double c1, double la1, double c2, double la2, int depth) {
    if (depth <= 0 || (la2 - la1).abs() <= 20.0) return;
    final cm = (c1 + c2) / 2;
    final lam = terminatorLat(cm);
    subdivide(c1, la1, cm, lam, depth - 1);
    night.add(toPlane(cm, lam));
    subdivide(cm, lam, c2, la2, depth - 1);
  }

  var prevC = -180.0;
  var prevLa = terminatorLat(-180.0);
  night.add(toPlane(-180.0, prevLa));
  while (prevC < 180) {
    var c2 = prevC + 2;
    if (c2 > 180) {
      c2 = 180.0;
    }
    final la2 = terminatorLat(c2);
    subdivide(prevC, prevLa, c2, la2, 7);
    night.add(toPlane(c2, la2));
    prevLa = la2;
    prevC = c2;
  }
  /* the closing follows the edges of the map ( centered longitudes 180
     and -180, the line of the pole in night ), sampled along the
     arcs: the Equal Earth projection curves the meridians, a straight
     chord between the curve and the pole left whole regions on the
     wrong side of the day / night limit */
  final edgeLat = prevLa;
  final step = nightPole > 0 ? 5.0 : -5.0;
  for (var la = edgeLat + step;
      step > 0 ? la <= nightPole : la >= nightPole;
      la += step) {
    night.add(toPlane(180, la));
  }
  night.add(toPlane(180, nightPole));
  for (var lo = 180.0; lo >= -180; lo -= 15) {
    night.add(toPlane(lo, nightPole));
  }
  for (var la = nightPole - step;
      step > 0 ? la >= edgeLat : la <= edgeLat;
      la -= step) {
    night.add(toPlane(-180, la));
  }
  night.add(toPlane(-180, edgeLat));
  return night;
}

/* sunrise and sunset time, standard formula; null when the sun never
   rises ( polar night or polar day ). */
List<DateTime?> sunriseSunset(double lat, double lon, DateTime dayUtc) {
  final n =
      (dayUtc.difference(DateTime(dayUtc.year, 1, 1)).inHours / 24).floor();
  final j = n + 0.5 - lon / 360 + 0.0009;
  final m = (357.5291 + 0.98560028 * j) % 360;
  final c = 1.9148 * math.sin(m * _rad) +
      0.02 * math.sin(2 * m * _rad) +
      0.0003 * math.sin(3 * m * _rad);
  final lambda = (m + c + 180 + 102.9372) % 360;
  final jt =
      j + 0.0053 * math.sin(m * _rad) - 0.0069 * math.sin(2 * lambda * _rad);
  final decl =
      math.asin(math.sin(lambda * _rad) * math.sin(23.4397 * _rad)) / _rad;
  final cosH =
      (math.sin(-0.833 * _rad) - math.sin(lat * _rad) * math.sin(decl * _rad)) /
          (math.cos(lat * _rad) * math.cos(decl * _rad));
  if (cosH < -1 || cosH > 1) return [null, null];
  final h = math.acos(cosH) / _rad / 15;
  final rise = DateTime.utc(dayUtc.year, 1, 1)
      .add(Duration(milliseconds: ((jt - h) * 86400000).round()));
  final set = DateTime.utc(dayUtc.year, 1, 1)
      .add(Duration(milliseconds: ((jt + h) * 86400000).round()));
  return [rise, set];
}