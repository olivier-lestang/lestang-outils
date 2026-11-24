/* Meteo : neufs sources publiques sans cle, releve unifie en codes WMO.
   Portage de js/meteo/meteo.js : villes editables persistees, recherche par
   geocoding Open-Meteo, source nationale par pays, lever et coucher du
   soleil calcules sur place.
   SPDX-License-Identifier : MIT. */
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../cartes/projection_monde.dart' show leverCoucher;
import '../l10n.dart';

/* ---------------- codes WMO : libelles francais et icones ---------------- */

const _wmo = <int, List<String>>{
  0: ['Ciel dégagé', '☀️'],
  1: ['Peu nuageux', '🌤️'],
  2: ['Partiellement nuageux', '⛅'],
  3: ['Couvert', '☁️'],
  45: ['Brouillard', '🌫️'],
  48: ['Brouillard givrant', '🌫️'],
  51: ['Bruine légère', '🌦️'],
  53: ['Bruine', '🌦️'],
  55: ['Bruine forte', '🌦️'],
  61: ['Pluie légère', '🌧️'],
  63: ['Pluie', '🌧️'],
  65: ['Pluie forte', '🌧️'],
  71: ['Neige légère', '🌨️'],
  73: ['Neige', '🌨️'],
  75: ['Neige forte', '❄️'],
  77: ['Grésil', '🌨️'],
  80: ['Averses légères', '🌦️'],
  81: ['Averses', '🌦️'],
  82: ['Averses fortes', '⛈️'],
  85: ['Averses de neige', '🌨️'],
  86: ['Fortes averses de neige', '❄️'],
  95: ['Orage', '⛈️'],
  96: ['Orage avec grêle', '⛈️'],
  99: ['Orage violent', '⛈️'],
};

List<String> wmoInfole(int code) => _wmo[code] ?? ['—', '🌡️'];

/* ---------------- sources nationales par pays ---------------- */

const _sources = <String, String>{
  'open-meteo': 'Open-Meteo',
  'meteofrance': 'Météo France',
  'metno': 'MET Norvège',
  'ipma': 'IPMA Portugal',
  'jma': 'JMA Japon',
  'nws': 'NWS États-Unis',
  'bom': 'BOM Australie',
  'hko': 'HKO Hong Kong',
  'wttr': 'wttr.in',
};

const _nationale = <String, String>{
  'FR': 'meteofrance',
  'NO': 'metno',
  'PT': 'ipma',
  'JP': 'jma',
  'US': 'nws',
  'PR': 'nws',
  'GU': 'nws',
  'VI': 'nws',
  'AS': 'nws',
  'MP': 'nws',
  'AU': 'bom',
  'HK': 'hko',
};

String sourceNationale(String? pays) =>
    pays == null ? 'open-meteo' : (_nationale[pays] ?? 'open-meteo');

/* ---------------- villes persistees ---------------- */

class VilleMeteo {
  final String nom;
  final String? pays;
  final double lat, lon;
  const VilleMeteo(this.nom, this.pays, this.lat, this.lon);

  String cle() => '$lat,$lon';

  Map<String, dynamic> versJson() => {'n': nom, 'p': pays, 'a': lat, 'o': lon};
  static VilleMeteo? depuisJson(dynamic j) {
    if (j is! Map) return null;
    final nom = j['n'], lat = j['a'], lon = j['o'];
    if (nom is! String || lat is! num || lon is! num) return null;
    return VilleMeteo(nom, j['p'] is String ? j['p'] as String? : null,
        lat.toDouble(), lon.toDouble());
  }
}

const villesParDefaut = <VilleMeteo>[
  VilleMeteo('Paris', 'FR', 48.8566, 2.3522),
  VilleMeteo('Lisbonne', 'PT', 38.7223, -9.1393),
  VilleMeteo('Rome', 'IT', 41.9028, 12.4964),
  VilleMeteo('Berlin', 'DE', 52.52, 13.405),
  VilleMeteo('Madrid', 'ES', 40.4168, -3.7038),
];

Future<List<VilleMeteo>> lireVilles() async {
  final p = await SharedPreferences.getInstance();
  final crus = p.getStringList('meteo-villes');
  if (crus == null || crus.isEmpty) return villesParDefaut;
  final villes = <VilleMeteo>[];
  for (final c in crus) {
    final v = VilleMeteo.depuisJson(jsonDecode(c));
    if (v != null) villes.add(v);
  }
  return villes.isEmpty ? villesParDefaut : villes;
}

Future<void> ecrireVilles(List<VilleMeteo> villes) async {
  final p = await SharedPreferences.getInstance();
  await p.setStringList(
      'meteo-villes', villes.map((v) => jsonEncode(v.versJson())).toList());
}

/* ---------------- releve unifie ---------------- */

class ReleveMeteo {
  final int code;
  final double temp, max, min, max2, min2;
  const ReleveMeteo(
      this.code, this.temp, this.max, this.min, this.max2, this.min2);
}

dynamic _get(dynamic d, String chemin) {
  for (final part in chemin.split('.')) {
    if (d is Map) {
      d = d[part];
    } else if (d is List && int.tryParse(part) != null) {
      final i = int.parse(part);
      d = (i >= 0 && i < d.length) ? d[i] : null;
    } else {
      return null;
    }
    if (d == null) return null;
  }
  return d;
}

Future<Map<String, dynamic>> _json(Uri u,
    {Map<String, String>? entetes}) async {
  final r = await http.get(u, headers: entetes);
  return jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
}

/* releve via les API Open-Meteo ( source meteofrance incluse ) */
Future<ReleveMeteo> _chargerOpenMeteo(VilleMeteo v, String cible) async {
  final d = await _json(Uri.parse('https://api.open-meteo.com/v1/' +
      cible +
      '?latitude=' +
      v.lat.toString() +
      '&longitude=' +
      v.lon.toString() +
      '&current=temperature_2m,weather_code' +
      '&daily=temperature_2m_max,temperature_2m_min&forecast_days=2&timezone=auto'));
  final c = _get(d, 'current') as Map<String, dynamic>;
  final q = _get(d, 'daily') as Map<String, dynamic>;
  double maxis(int i) =>
      ((q['temperature_2m_max'] as List)[i] as num).toDouble();
  double minis(int i) =>
      ((q['temperature_2m_min'] as List)[i] as num).toDouble();
  return ReleveMeteo(
      (c['weather_code'] as num).toInt(),
      (c['temperature_2m'] as num).toDouble(),
      maxis(0),
      minis(0),
      maxis(1),
      minis(1));
}

const _wttrVersWmo = <int, int>{
  113: 0,
  116: 2,
  119: 3,
  122: 3,
  143: 45,
  176: 51,
  179: 71,
  182: 77,
  185: 77,
  200: 95,
  227: 71,
  230: 73,
  248: 45,
  260: 45,
  263: 53,
  266: 55,
  281: 61,
  284: 66,
  294: 61,
  299: 80,
  302: 80,
  305: 81,
  308: 81,
  311: 82,
  314: 82,
  317: 71,
  320: 73,
  350: 51,
  353: 80,
  356: 81,
  359: 82,
  362: 85,
  365: 85,
  371: 73,
  377: 75,
  386: 95,
  389: 95,
  392: 95,
  395: 95,
};

Future<ReleveMeteo> _chargerWttr(VilleMeteo v) async {
  final q = '${v.lat},${v.lon}';
  final d = await _json(
      Uri.parse('https://wttr.in/${Uri.encodeComponent(q)}?format=j1&lang=fr'));
  final c = (d['current_condition'] as List)[0] as Map<String, dynamic>;
  final jours = d['weather'] as List;
  double du(dynamic j, String cle) =>
      double.parse(((j as Map<String, dynamic>)[cle] as String?) ?? '0');
  final code = int.tryParse(c['weatherCode'] as String? ?? '') ?? 3;
  return ReleveMeteo(
      _wttrVersWmo[code] ?? 3,
      double.parse(c['temp_C'] as String),
      du(jours[0], 'maxtempC'),
      du(jours[0], 'mintempC'),
      du(jours[1], 'maxtempC'),
      du(jours[1], 'mintempC'));
}

const _metnoVersWmo = <String, int>{
  'clearsky': 0,
  'fair': 1,
  'partlycloudy': 2,
  'cloudy': 3,
  'fog': 45,
  'lightrain': 61,
  'rain': 63,
  'heavyrain': 65,
  'lightrainshowers': 80,
  'rainshowers': 81,
  'heavyrainshowers': 82,
  'lightsleet': 77,
  'sleet': 77,
  'heavysleet': 77,
  'lightsnow': 71,
  'snow': 73,
  'heavysnow': 75,
  'lightsnowshowers': 85,
  'snowshowers': 85,
  'heavysnowshowers': 86,
  'thunder': 95,
  'thunderstorm': 95,
};

Future<ReleveMeteo> _chargerMetno(VilleMeteo v) async {
  final d = await _json(
      Uri.parse('https://api.met.no/weatherapi/locationforecast/2.0/compact'
          '?lat=${v.lat}&lon=${v.lon}'),
      entetes: {'User-Agent': 'Lestang-Outils lestang@example.org'});
  final serie = _get(d, 'properties.timeseries') as List;
  final maintenant = DateTime.now().toUtc();
  Map<String, dynamic>? courant, plusTard;
  for (final e in serie) {
    final t = DateTime.parse((e as Map)['time'] as String);
    if (!t.isAfter(maintenant)) courant = e as Map<String, dynamic>;
    if (plusTard == null &&
        t.isAfter(maintenant.add(const Duration(hours: 2)))) {
      plusTard = e as Map<String, dynamic>;
    }
  }
  final base = (courant ?? serie.first) as Map<String, dynamic>;
  final symbole = ((_get(base, 'data.next_1_hours.summary.symbol_code') ??
          _get(base, 'data.next_6_hours.summary.symbol_code')) as String?)
      ?.split('_')
      .first;
  double temps(dynamic e) =>
      ((_get(e, 'data.instant.details.air_temperature') as num?) ?? 0)
          .toDouble();
  final t = temps(base);
  return ReleveMeteo(_metnoVersWmo[symbole] ?? 3, t, t, t,
      temps(plusTard ?? serie.last), temps(plusTard ?? serie.last));
}

const _ipmaVersWmo = <int, int>{
  1: 0,
  2: 1,
  3: 2,
  4: 3,
  5: 51,
  6: 63,
  7: 65,
  8: 65,
  9: 61,
  10: 80,
  11: 81,
  12: 82,
  13: 82,
  14: 77,
  15: 77,
  16: 71,
  17: 73,
  18: 75,
  19: 75,
  20: 95,
  21: 95,
  22: 95,
  23: 95,
  24: 85,
  25: 96,
  26: 45,
  27: 45,
  28: 3,
  29: 45,
  30: 45,
};

double _carre(double x) => x * x;

Future<ReleveMeteo> _chargerIpma(VilleMeteo v) async {
  final dj = await _json(
      Uri.parse('https://api.ipma.pt/open-data/distrits-islands.json'));
  final liste = dj['data'] as List;
  Map<String, dynamic>? meilleur;
  var meilleure = 1e9;
  for (final e in liste) {
    final m = e as Map<String, dynamic>;
    final dd = _carre((m['latitude'] as num).toDouble() - v.lat) +
        _carre((m['longitude'] as num).toDouble() - v.lon);
    if (dd < meilleure) {
      meilleure = dd;
      meilleur = m;
    }
  }
  final f = await _json(Uri.parse(
      'https://api.ipma.pt/open-data/forecast/meteorology/cities/daily/'
      '${meilleur!['globalIdLocal']}.json'));
  final jours = f['data'] as List;
  final d0 = jours[0] as Map<String, dynamic>;
  final d1 = jours[1] as Map<String, dynamic>;
  return ReleveMeteo(
      _ipmaVersWmo[int.parse(d0['idWeatherType'] as String)] ?? 3,
      ((d0['tMin'] as num) + (d0['tMax'] as num)) / 2,
      (d0['tMax'] as num).toDouble(),
      (d0['tMin'] as num).toDouble(),
      (d1['tMax'] as num).toDouble(),
      (d1['tMin'] as num).toDouble());
}

/* prefectures du Japon : code, latitude, longitude */
const _prefecturesJma = <List<double>>[
  [16, 43.06, 141.35],
  [20, 40.82, 140.75],
  [30, 39.70, 141.15],
  [40, 38.27, 140.87],
  [50, 39.72, 140.10],
  [60, 38.24, 140.36],
  [70, 37.75, 140.47],
  [80, 36.34, 140.45],
  [90, 36.57, 139.88],
  [100, 36.37, 139.06],
  [110, 35.86, 139.65],
  [120, 35.60, 140.12],
  [130, 35.69, 139.69],
  [140, 35.45, 139.64],
  [150, 37.02, 138.37],
  [160, 36.70, 137.21],
  [170, 36.59, 136.63],
  [180, 36.06, 136.22],
  [190, 35.66, 138.57],
  [200, 36.21, 138.17],
  [210, 35.39, 137.21],
  [220, 34.98, 138.38],
  [230, 35.18, 136.91],
  [240, 34.23, 136.52],
  [250, 35.00, 135.87],
  [260, 35.01, 135.77],
  [270, 34.69, 135.50],
  [280, 34.69, 135.18],
  [290, 34.01, 135.83],
  [300, 33.84, 135.53],
  [310, 35.29, 134.24],
  [320, 35.07, 132.90],
  [330, 34.66, 133.93],
  [340, 34.40, 132.46],
  [350, 34.19, 131.47],
  [360, 34.07, 134.56],
  [370, 34.34, 134.04],
  [380, 33.84, 132.77],
  [390, 33.56, 133.53],
  [400, 33.61, 130.42],
  [410, 33.25, 130.30],
  [420, 32.84, 129.73],
  [430, 32.79, 130.74],
  [440, 33.24, 131.61],
  [450, 32.32, 131.44],
  [460, 31.60, 130.56],
  [471, 26.21, 127.68],
];

int _codeJma(int c) {
  if (c == 100 || c == 101 || c == 110) return 0;
  if (c == 102) return 2;
  if (c == 104) return 1;
  if (c >= 200 && c <= 206) return (c == 200 || c == 201) ? 2 : 3;
  if ((c >= 300 && c <= 320)) return 63;
  if (c == 400 ||
      c == 401 ||
      c == 402 ||
      c == 403 ||
      c == 405 ||
      c == 407 ||
      c == 409 ||
      c == 411 ||
      c == 413 ||
      c == 414 ||
      c == 416) return 73;
  if (c >= 500 && c <= 503) return 77;
  if (c == 600 ||
      c == 601 ||
      c == 602 ||
      c == 604 ||
      c == 607 ||
      c == 608 ||
      c == 609) return 95;
  return 3;
}

Future<ReleveMeteo> _chargerJma(VilleMeteo v) async {
  var meilleur = _prefecturesJma[0];
  var meilleure = 1e9;
  for (final p in _prefecturesJma) {
    final dd = _carre(p[1] - v.lat) + _carre(p[2] - v.lon);
    if (dd < meilleure) {
      meilleure = dd;
      meilleur = p;
    }
  }
  final code = (meilleur[0].round().toString() + '0000')
      .padLeft(6, ' ')
      .replaceAll(' ', '0');
  final d = await _json(Uri.parse(
      'https://www.jma.go.jp/bosai/forecast/data/forecast/$code.json'));
  final ts = (_get(d, '0.timeSeries') as List?) ?? const [];
  final codeMeteo = int.tryParse(
      '${_get(ts.isEmpty ? null : ts[0], 'areas.areas.0.weatherCodes.0') ?? ''}');
  final zoneTemps = ts.length > 2 ? ts[2] as Map<String, dynamic> : null;
  final defs = (zoneTemps?['timeDefines'] as List?) ?? const [];
  final tempsDeZone =
      (_get(zoneTemps, 'areas.areas.0.temps') as List?) ?? const [];
  /* releves : 0 h donne le minimum du jour, 9 h le maximum ( heures du Japon ) */
  final parJour = <String, Map<String, double>>{};
  for (var j = 0; j < defs.length && j < tempsDeZone.length; j++) {
    final valeur = double.tryParse('${tempsDeZone[j]}');
    if (valeur == null) continue;
    final def = defs[j] as String;
    final jour = def.substring(0, 10);
    final hh = def.length > 12 ? int.tryParse(def.substring(11, 13)) : null;
    final e = parJour.putIfAbsent(jour, () => <String, double>{});
    if (hh == 9) {
      e['max'] = valeur;
    } else if (hh == 0) {
      e['min'] = valeur;
    }
  }
  final maintenantJapon = DateTime.now().toUtc().add(const Duration(hours: 9));
  final jour1 = maintenantJapon.toString().substring(0, 10);
  final jour2 =
      maintenantJapon.add(const Duration(days: 1)).toString().substring(0, 10);
  var tmin = parJour[jour1]?['min'] ??
      (tempsDeZone.length > 1
          ? double.tryParse('${tempsDeZone[1]}') ?? 0
          : 0.0);
  var tmax = parJour[jour1]?['max'] ??
      (tempsDeZone.isNotEmpty
          ? double.tryParse('${tempsDeZone[0]}') ?? 0
          : 0.0);
  final tmin2 = parJour[jour2]?['min'] ??
      (tempsDeZone.length > 2
          ? double.tryParse('${tempsDeZone[2]}') ?? tmin
          : tmin);
  final tmax2 = parJour[jour2]?['max'] ??
      (tempsDeZone.length > 3
          ? double.tryParse('${tempsDeZone[3]}') ?? tmax
          : tmax);
  /* interpolation jour et nuit : estimation de la temperature du moment */
  final h = (DateTime.now().millisecondsSinceEpoch / 3600000 + 9) % 24;
  final f = h < 5
      ? 0.05
      : h < 9
          ? 0.30
          : h < 13
              ? 0.55
              : h < 17
                  ? 0.85
                  : h < 21
                      ? 0.65
                      : 0.35;
  final temp = tmin + (tmax - tmin) * f;
  return ReleveMeteo(_codeJma(codeMeteo ?? -1), temp, tmax, tmin, tmax2, tmin2);
}

const _reglesNws = <List<Object>>[
  ['thunderstorm', 95],
  ['hail', 96],
  ['freezing rain', 66],
  ['sleet', 77],
  ['snow', 73],
  ['rain showers', 80],
  ['showers', 81],
  ['drizzle', 51],
  ['rain', 63],
  ['fog', 45],
  ['haze', 45],
  ['smoke', 45],
  ['blowing snow', 71],
  ['sunny', 0],
  ['clear', 0],
  ['mostly sunny', 1],
  ['mostly clear', 1],
  ['partly sunny', 2],
  ['partly cloudy', 2],
  ['cloudy', 3],
];

int _codeNws(String description) {
  final d = description.toLowerCase();
  for (final regle in _reglesNws) {
    if (d.contains(regle[0] as String)) return regle[1] as int;
  }
  return 3;
}

Future<ReleveMeteo> _chargerNws(VilleMeteo v) async {
  final p = await _json(Uri.parse(
      'https://api.weather.gov/points/${v.lat.toStringAsFixed(4)},${v.lon.toStringAsFixed(4)}'));
  final url = _get(p, 'properties.forecastHourly') as String?;
  if (url == null) throw const HttpException('nws');
  final f = await _json(Uri.parse(url));
  final periodes = _get(f, 'properties.periods') as List;
  if (periodes.isEmpty) throw const HttpException('nws');
  final premier = periodes.first as Map<String, dynamic>;
  /* min et max par date locale des periodes */
  final jours = <String, List<double>>{};
  for (final e in periodes) {
    final m = e as Map<String, dynamic>;
    final jour = (m['startTime'] as String).substring(0, 10);
    final valeur = double.tryParse('${m['temperature']}') ?? 0;
    final minmax = jours.putIfAbsent(jour, () => [valeur, valeur]);
    if (valeur < minmax[0]) minmax[0] = valeur;
    if (valeur > minmax[1]) minmax[1] = valeur;
  }
  final cles = jours.keys.toList()..sort();
  if (cles.length < 2) throw const HttpException('nws');
  return ReleveMeteo(
      _codeNws((premier['shortForecast'] as String?) ?? ''),
      double.tryParse('${premier['temperature']}') ?? 0,
      jours[cles[0]]![1],
      jours[cles[0]]![0],
      jours[cles[1]]![1],
      jours[cles[1]]![0]);
}

const _bomVersWmo = <String, int>{
  'clear': 0,
  'sunny': 0,
  'mostly_sunny': 1,
  'partly_cloudy': 2,
  'cloudy': 3,
  'fog': 45,
  'showers': 80,
  'shower': 80,
  'rain': 63,
  'snow': 73,
  'storm': 95,
  'thunderstorms': 95,
  'dust': 45,
  'hail': 96,
  'wind': 3,
  'frost': 71,
  'hot': 3,
  'cold': 3,
};

Future<ReleveMeteo> _chargerBom(VilleMeteo v) async {
  final s = await _json(Uri.parse(
      'https://api.weather.bom.gov.au/v1/locations?search=${Uri.encodeComponent(v.nom)}'));
  final g = _get(s, 'data.0') as Map<String, dynamic>?;
  if (g == null) throw const HttpException('bom');
  final f = await _json(Uri.parse(
      'https://api.weather.bom.gov.au/v1/locations/${g['geohash']}/forecasts/daily'));
  final d0 = _get(f, 'data.0') as Map<String, dynamic>;
  final d1 = _get(f, 'data.1') as Map<String, dynamic>;
  final temp = (_get(d0, 'now.temp_now') as num?)?.toDouble() ??
      (((d0['temp_min'] as num) + (d0['temp_max'] as num)) / 2);
  return ReleveMeteo(
      _bomVersWmo[d0['icon_descriptor'] as String? ?? ''] ?? 3,
      temp,
      (d0['temp_max'] as num).toDouble(),
      (d0['temp_min'] as num).toDouble(),
      (d1['temp_max'] as num).toDouble(),
      (d1['temp_min'] as num).toDouble());
}

const _hkoVersWmo = <int, int>{
  50: 0,
  51: 1,
  52: 2,
  53: 80,
  54: 80,
  60: 3,
  61: 3,
  62: 61,
  63: 63,
  64: 65,
  65: 95,
  70: 0,
  71: 0,
  72: 0,
  73: 0,
  74: 0,
  75: 2,
  76: 1,
  77: 1,
  80: 3,
  81: 0,
  82: 2,
  83: 45,
  84: 45,
  85: 45,
  90: 0,
  91: 1,
  92: 2,
  93: 3,
};

Future<ReleveMeteo> _chargerHko(VilleMeteo v) async {
  const base = 'https://data.weather.gov.hk/weatherAPI/opendata/weather.php';
  final f = await _json(Uri.parse('$base?dataType=fnd&lang=en'));
  final d0 = _get(f, 'weatherForecast.0') as Map<String, dynamic>;
  final d1 = _get(f, 'weatherForecast.1') as Map<String, dynamic>;
  var code = _hkoVersWmo[int.tryParse('${d0['ForecastIcon']}') ?? -1] ?? 3;
  final r = await _json(Uri.parse('$base?dataType=rhrread&lang=en'));
  var temp = 0.0;
  final serie = _get(r, 'temperature.data') as List?;
  for (final e in serie ?? const []) {
    if ((e as Map<String, dynamic>)['place'] == 'Hong Kong Observatory') {
      temp = (e['value'] as num).toDouble();
    }
  }
  final min0 = (_get(d0, 'forecastMintemp.value') as num).toDouble();
  final max0 = (_get(d0, 'forecastMaxtemp.value') as num).toDouble();
  final min1 = (_get(d1, 'forecastMintemp.value') as num).toDouble();
  final max1 = (_get(d1, 'forecastMaxtemp.value') as num).toDouble();
  /* la temperature du siege de l Observatoire manque : moyenne des extremes du jour */
  if (temp == 0.0) temp = (min0 + max0) / 2;
  /* icone du releve courant si disponible, sinon celle de la prevision */
  final iconeRele = _hkoVersWmo[((_get(r, 'icon.0') as num?) ?? -1).toInt()];
  if (iconeRele != null) code = iconeRele;
  return ReleveMeteo(code, temp, max0, min0, max1, min1);
}

/* orchestre : la source demandee, puis Open-Meteo, puis wttr.in en secours */
Future<ReleveMeteo> chargerMeteo(VilleMeteo v, String source) async {
  final chargeurs = <String, Future<ReleveMeteo> Function(VilleMeteo)>{
    'meteofrance': (v2) => _chargerOpenMeteo(v2, 'meteofrance'),
    'metno': _chargerMetno,
    'ipma': _chargerIpma,
    'jma': _chargerJma,
    'nws': _chargerNws,
    'bom': _chargerBom,
    'hko': _chargerHko,
    'wttr': _chargerWttr,
  };
  Object? derniere;
  for (final s in [source, 'open-meteo', 'wttr']) {
    try {
      if (s == 'open-meteo') return await _chargerOpenMeteo(v, 'forecast');
      final f = chargeurs[s];
      if (f != null) return await f(v);
    } catch (e) {
      derniere = e;
    }
  }
  throw derniere ?? const HttpException('meteo');
}

/* ---------------- l ecran ---------------- */

class EcranMeteo extends StatefulWidget {
  final Traducteur trad;
  const EcranMeteo(this.trad, {super.key});

  @override
  State<EcranMeteo> createState() => _EcranMeteoState();
}

class _EcranMeteoState extends State<EcranMeteo> {
  final _recherche = TextEditingController();
  List<VilleMeteo>? _villes;
  int _courante = 0;
  final Map<String, ReleveMeteo> _releves = {};
  final Map<String, String> _erreurs = {};
  bool _occupe = false;
  List<VilleMeteo>? _suggestions;

  @override
  void initState() {
    super.initState();
    lireVilles().then((v) {
      if (mounted) {
        setState(() => _villes = v);
        _chargerCourante();
      }
    });
  }

  VilleMeteo get ville => _villes == null
      ? villesParDefaut.first
      : _villes![_courante.clamp(0, _villes!.length - 1)];

  Future<void> _chargerCourante() async {
    if (_villes == null) return;
    final v = ville;
    if (_releves.containsKey(v.cle())) return;
    setState(() => _occupe = true);
    try {
      final r = await chargerMeteo(v, sourceNationale(v.pays));
      if (mounted) setState(() => _releves[v.cle()] = r);
    } catch (_) {
      if (mounted) {
        setState(() => _erreurs[v.cle()] = widget.trad('meteo-erreur'));
      }
    } finally {
      if (mounted) setState(() => _occupe = false);
    }
  }

  Future<void> _chercher(String q) async {
    if (q.trim().length < 2) return;
    try {
      final r = await http.get(Uri.parse(
          'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(q.trim())}&count=8&language=fr&format=json'));
      final d = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      final res = (d['results'] as List?) ?? const [];
      final trouve = <VilleMeteo>[];
      for (final e in res) {
        final j = e as Map<String, dynamic>;
        trouve.add(VilleMeteo(
            (j['name'] as String?) ?? '',
            j['country_code'] as String?,
            (j['latitude'] as num).toDouble(),
            (j['longitude'] as num).toDouble()));
      }
      if (mounted) setState(() => _suggestions = trouve);
    } catch (_) {}
  }

  Future<void> _ajouter(VilleMeteo v) async {
    final villes = [...?_villes, v];
    await ecrireVilles(villes);
    setState(() {
      _villes = villes;
      _courante = villes.length - 1;
      _suggestions = null;
      _recherche.clear();
    });
    _chargerCourante();
  }

  Future<void> _supprimer(int i) async {
    final villes = [..._villes!..removeAt(i)];
    await ecrireVilles(villes);
    setState(() {
      _villes = villes;
      _courante = 0;
    });
  }

  String _leverCoucher() {
    final maintenant = DateTime.now();
    final lc = leverCoucher(ville.lat, ville.lon, maintenant.toUtc());
    String Heure(DateTime? d) =>
        d == null ? '—' : d.toLocal().toString().substring(11, 16);
    return '↑ ${Heure(lc[0])}   ↓ ${Heure(lc[1])}';
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.trad;
    if (_villes == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final releve = _releves[ville.cle()];
    final info = releve == null ? null : wmoInfole(releve.code);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (var i = 0; i < _villes!.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InputChip(
                  label: Text(_villes![i].nom),
                  selected: i == _courante,
                  onSelected: (_) {
                    setState(() {
                      _courante = i;
                      _chargerCourante();
                    });
                  },
                  onDeleted: () => _supprimer(i),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _recherche,
        decoration: InputDecoration(
          labelText: t('meteo-chercher'),
          isDense: true,
          suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _chercher(_recherche.text)),
        ),
        onSubmitted: _chercher,
      ),
      if (_suggestions != null && _suggestions!.isNotEmpty) ...[
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final s in _suggestions!)
              ActionChip(
                  label: Text('${s.nom} (${s.pays ?? '?'})'),
                  onPressed: () => _ajouter(s)),
          ],
        ),
      ],
      const SizedBox(height: 12),
      if (_occupe) const CircularProgressIndicator(),
      if (releve != null) ...[
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Text(info![1], style: const TextStyle(fontSize: 34)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${releve.temp.toStringAsFixed(0)} °C',
                        style: const TextStyle(fontSize: 26)),
                    Text(
                        '${info[0]} · max ${releve.max.toStringAsFixed(0)} ° · min ${releve.min.toStringAsFixed(0)} °'),
                    Text(
                        '${t('demain')} : max ${releve.max2.toStringAsFixed(0)} ° · min ${releve.min2.toStringAsFixed(0)} °'),
                    const SizedBox(height: 4),
                    Text(_leverCoucher()),
                  ]),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Text('${t('source')} : ${_sources[sourceNationale(ville.pays)]}',
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
      if (_erreurs[ville.cle()] != null)
        Text(_erreurs[ville.cle()]!,
            style: const TextStyle(color: Colors.red, fontSize: 13)),
    ]);
  }
}
