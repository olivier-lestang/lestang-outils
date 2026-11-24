/* Projection Equal Earth du web ( js/monde/carte-monde.js ) : les memes
   coefficients, la meme inversion Newton ; plus le point subsolaire et le
   polygone de nuit pour l ensoleillement de la carte du monde.
   SPDX-License-Identifier : MIT. */
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

/* latitude et longitude en degres vers le plan normalise [-1..1] */
Offset ee(double lat, double lon) {
  final th = math.asin(_eeM * math.sin(lat * _rad));
  return Offset(
      lon * _rad * math.cos(th) * _eeCoef(th) / eeXmax, _eeLat(th) / eeYmax);
}

/* plan normalise vers latitude et longitude en degres ( Newton, comme d3-geo ) */
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

/* ---------------- point subsolaire ( declinaison NOAA + equation du temps ) ---------------- */

class PointSolaire {
  final double lat, lon;
  const PointSolaire(this.lat, this.lon);
}

PointSolaire pointSolaire(DateTime utc) {
  final ms = utc.millisecondsSinceEpoch.toDouble();
  final sj = (ms / 86400000 + 2440587.5 - 2451545) / 36525;
  final lonMoy = (280.46646 + sj * (36000.76983 + 0.0003032 * sj)) % 360;
  final anom = 357.52911 + sj * (35999.05029 - 0.0001537 * sj);
  final exc = 0.016708634 - sj * (0.000042037 + 0.0000001267 * sj);
  final eqCentre =
      math.sin(anom * _rad) * (1.914602 - sj * (0.004817 + 0.000014 * sj)) +
          math.sin(2 * anom * _rad) * (0.019993 - 0.000101 * sj) +
          math.sin(3 * anom * _rad) * 0.000289;
  final lonApp = lonMoy +
      eqCentre -
      0.00569 -
      0.00478 * math.sin((125.04 - 1934.136 * sj) * _rad);
  final oblMoyen = 23 +
      (26 + ((21.448 - sj * (46.815 + sj * (0.00059 - sj * 0.001813))) / 60)) /
          60;
  final oblVrai =
      oblMoyen + 0.00256 * math.cos((125.04 - 1934.136 * sj) * _rad);
  final decl =
      math.asin(math.sin(oblVrai * _rad) * math.sin(lonApp * _rad)) / _rad;
  final tanCarre = math.tan(oblVrai / 2 * _rad) * math.tan(oblVrai / 2 * _rad);
  final eqTemps = 4 *
      (tanCarre * math.sin(2 * lonMoy * _rad) -
          2 * exc * math.sin(anom * _rad) +
          4 *
              exc *
              tanCarre *
              math.sin(anom * _rad) *
              math.cos(2 * lonMoy * _rad) -
          0.5 * tanCarre * tanCarre * math.sin(4 * lonMoy * _rad) -
          1.25 * exc * exc * math.sin(2 * anom * _rad)) /
      _rad;
  var lon = -(((ms / 3600000) % 24) + eqTemps / 60 - 12) * 15;
  lon = ((lon + 540) % 360) - 180;
  return PointSolaire(decl, lon);
}

/* ---------------- polygone de nuit ---------------- */

/* Les sommets du polygone nuit, en plan normalise : la courbe terminatrice
   puis la fermeture par le pole en nuit. Il reste au dessinateur a y
   appliquer le cadrage et a remplir. */
List<Offset> polygoneNuit(PointSolaire soleil, {double meridien = 0}) {
  final sinLat = math.sin(soleil.lat * _rad);
  final cosLat = math.cos(soleil.lat * _rad);
  Offset versPlan(double lon, double lat) {
    var l = (lon - meridien) % 360.0;
    if (l > 180) {
      l -= 360;
    } else if (l < -180) {
      l += 360;
    }
    return ee(lat, l);
  }

  final nuit = <Offset>[];
  if (sinLat.abs() < 1e-9) {
    /* equinoxe exact : moitie du plan en longitude */
    final a = ((soleil.lon + 90 + 540) % 360) - 180;
    for (var la = -90.0; la <= 90; la += 5) {
      nuit.add(versPlan(a + 180, la));
    }
    for (var la = 90.0; la >= -90; la -= 5) {
      nuit.add(versPlan(a, la));
    }
    return nuit;
  }
  final poleNuit = sinLat < 0 ? 90.0 : -90.0;
  for (var lon = -180.0; lon <= 180; lon += 2) {
    final latTerme =
        math.atan(-cosLat * math.cos((lon - soleil.lon) * _rad) / sinLat) /
            _rad;
    nuit.add(versPlan(lon, latTerme));
  }
  nuit.add(versPlan(180, poleNuit));
  nuit.add(versPlan(-180, poleNuit));
  return nuit;
}

/* heure de lever et de coucher du soleil, formule standard ; null quand
   le soleil ne se leve pas ( nuit ou jour polaire ). */
List<DateTime?> leverCoucher(double lat, double lon, DateTime jourUtc) {
  final n =
      (jourUtc.difference(DateTime(jourUtc.year, 1, 1)).inHours / 24).floor();
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
  final lever = DateTime.utc(jourUtc.year, 1, 1)
      .add(Duration(milliseconds: ((jt - h) * 86400000).round()));
  final coucher = DateTime.utc(jourUtc.year, 1, 1)
      .add(Duration(milliseconds: ((jt + h) * 86400000).round()));
  return [lever, coucher];
}
