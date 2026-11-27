/* Weather: nine public sources without a key, unified reading in WMO
   codes. Port of js/meteo/meteo.js: editable persisted cities, search
   by Open-Meteo geocoding, national source per country, sunrise and
   sunset computed on the spot.
   SPDX-License-Identifier: MIT. */
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n.dart';
import '../maps/world_projection.dart' show sunriseSunset;

/* ---------------- WMO codes: French labels and icons ---------------- */

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

List<String> wmoInfo(int code) => _wmo[code] ?? ['—', '🌡️'];

/* ---------------- national sources per country ---------------- */

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

const _national = <String, String>{
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

String nationalSource(String? country) =>
    country == null ? 'open-meteo' : (_national[country] ?? 'open-meteo');

/* ---------------- persisted cities ---------------- */

class WeatherCity {
  final String name;
  final String? country;
  final double lat, lon;
  const WeatherCity(this.name, this.country, this.lat, this.lon);

  String key() => '$lat,$lon';

  Map<String, dynamic> toJson() => {'n': name, 'p': country, 'a': lat, 'o': lon};
  static WeatherCity? fromJson(dynamic j) {
    if (j is! Map) return null;
    final name = j['n'], lat = j['a'], lon = j['o'];
    if (name is! String || lat is! num || lon is! num) return null;
    return WeatherCity(name, j['p'] is String ? j['p'] as String? : null,
        lat.toDouble(), lon.toDouble());
  }
}

const defaultCities = <WeatherCity>[
  WeatherCity('Paris', 'FR', 48.8566, 2.3522),
  WeatherCity('Lisbonne', 'PT', 38.7223, -9.1393),
  WeatherCity('Rome', 'IT', 41.9028, 12.4964),
  WeatherCity('Berlin', 'DE', 52.52, 13.405),
  WeatherCity('Madrid', 'ES', 40.4168, -3.7038),
];

Future<List<WeatherCity>> readCities() async {
  final p = await SharedPreferences.getInstance();
  final raw = p.getStringList('meteo-villes');
  if (raw == null || raw.isEmpty) return defaultCities;
  final cities = <WeatherCity>[];
  for (final c in raw) {
    final v = WeatherCity.fromJson(jsonDecode(c));
    if (v != null) cities.add(v);
  }
  return cities.isEmpty ? defaultCities : cities;
}

Future<void> writeCities(List<WeatherCity> cities) async {
  final p = await SharedPreferences.getInstance();
  await p.setStringList(
      'meteo-villes', cities.map((v) => jsonEncode(v.toJson())).toList());
}

/* ---------------- unified reading ---------------- */

class WeatherReading {
  final int code;
  final double temp, max, min, max2, min2;
  const WeatherReading(
      this.code, this.temp, this.max, this.min, this.max2, this.min2);
}

dynamic _get(dynamic d, String path) {
  for (final part in path.split('.')) {
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
    {Map<String, String>? headers}) async {
  final r = await http.get(u, headers: headers);
  return jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
}

/* reading via the Open-Meteo APIs ( meteofrance source included ) */
Future<WeatherReading> _loadOpenMeteo(WeatherCity v, String target) async {
  final d = await _json(Uri.parse('https://api.open-meteo.com/v1/' +
      target +
      '?latitude=' +
      v.lat.toString() +
      '&longitude=' +
      v.lon.toString() +
      '&current=temperature_2m,weather_code' +
      '&daily=temperature_2m_max,temperature_2m_min&forecast_days=2&timezone=auto'));
  final c = _get(d, 'current') as Map<String, dynamic>;
  final q = _get(d, 'daily') as Map<String, dynamic>;
  double maxAt(int i) =>
      ((q['temperature_2m_max'] as List)[i] as num).toDouble();
  double minAt(int i) =>
      ((q['temperature_2m_min'] as List)[i] as num).toDouble();
  return WeatherReading(
      (c['weather_code'] as num).toInt(),
      (c['temperature_2m'] as num).toDouble(),
      maxAt(0),
      minAt(0),
      maxAt(1),
      minAt(1));
}

const _wttrToWmo = <int, int>{
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

Future<WeatherReading> _loadWttr(WeatherCity v) async {
  final q = '${v.lat},${v.lon}';
  final d = await _json(
      Uri.parse('https://wttr.in/${Uri.encodeComponent(q)}?format=j1&lang=fr'));
  final c = (d['current_condition'] as List)[0] as Map<String, dynamic>;
  final days = d['weather'] as List;
  double of(dynamic j, String key) =>
      double.parse(((j as Map<String, dynamic>)[key] as String?) ?? '0');
  final code = int.tryParse(c['weatherCode'] as String? ?? '') ?? 3;
  return WeatherReading(
      _wttrToWmo[code] ?? 3,
      double.parse(c['temp_C'] as String),
      of(days[0], 'maxtempC'),
      of(days[0], 'mintempC'),
      of(days[1], 'maxtempC'),
      of(days[1], 'mintempC'));
}

const _metnoToWmo = <String, int>{
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

Future<WeatherReading> _loadMetno(WeatherCity v) async {
  final d = await _json(
      Uri.parse('https://api.met.no/weatherapi/locationforecast/2.0/compact'
          '?lat=${v.lat}&lon=${v.lon}'),
      headers: {'User-Agent': 'Lestang-Outils lestang@example.org'});
  final series = _get(d, 'properties.timeseries') as List;
  final now = DateTime.now().toUtc();
  Map<String, dynamic>? current, later;
  for (final e in series) {
    final t = DateTime.parse((e as Map)['time'] as String);
    if (!t.isAfter(now)) current = e as Map<String, dynamic>;
    if (later == null &&
        t.isAfter(now.add(const Duration(hours: 2)))) {
      later = e as Map<String, dynamic>;
    }
  }
  final base = (current ?? series.first) as Map<String, dynamic>;
  final symbol = ((_get(base, 'data.next_1_hours.summary.symbol_code') ??
          _get(base, 'data.next_6_hours.summary.symbol_code')) as String?)
      ?.split('_')
      .first;
  double tempOf(dynamic e) =>
      ((_get(e, 'data.instant.details.air_temperature') as num?) ?? 0)
          .toDouble();
  final t = tempOf(base);
  return WeatherReading(_metnoToWmo[symbol] ?? 3, t, t, t,
      tempOf(later ?? series.last), tempOf(later ?? series.last));
}

const _ipmaToWmo = <int, int>{
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

double _sq(double x) => x * x;

Future<WeatherReading> _loadIpma(WeatherCity v) async {
  final dj = await _json(
      Uri.parse('https://api.ipma.pt/open-data/distrits-islands.json'));
  final list = dj['data'] as List;
  Map<String, dynamic>? best;
  var bestScore = 1e9;
  for (final e in list) {
    final m = e as Map<String, dynamic>;
    final dd = _sq((m['latitude'] as num).toDouble() - v.lat) +
        _sq((m['longitude'] as num).toDouble() - v.lon);
    if (dd < bestScore) {
      bestScore = dd;
      best = m;
    }
  }
  final f = await _json(Uri.parse(
      'https://api.ipma.pt/open-data/forecast/meteorology/cities/daily/'
      '${best!['globalIdLocal']}.json'));
  final days = f['data'] as List;
  final d0 = days[0] as Map<String, dynamic>;
  final d1 = days[1] as Map<String, dynamic>;
  return WeatherReading(
      _ipmaToWmo[int.parse(d0['idWeatherType'] as String)] ?? 3,
      ((d0['tMin'] as num) + (d0['tMax'] as num)) / 2,
      (d0['tMax'] as num).toDouble(),
      (d0['tMin'] as num).toDouble(),
      (d1['tMax'] as num).toDouble(),
      (d1['tMin'] as num).toDouble());
}

/* prefectures of Japan: code, latitude, longitude */
const _jmaPrefectures = <List<double>>[
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

int _jmaCode(int c) {
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

Future<WeatherReading> _loadJma(WeatherCity v) async {
  var best = _jmaPrefectures[0];
  var bestScore = 1e9;
  for (final p in _jmaPrefectures) {
    final dd = _sq(p[1] - v.lat) + _sq(p[2] - v.lon);
    if (dd < bestScore) {
      bestScore = dd;
      best = p;
    }
  }
  final code = (best[0].round().toString() + '0000')
      .padLeft(6, ' ')
      .replaceAll(' ', '0');
  final d = await _json(Uri.parse(
      'https://www.jma.go.jp/bosai/forecast/data/forecast/$code.json'));
  final ts = (_get(d, '0.timeSeries') as List?) ?? const [];
  final weatherCode = int.tryParse(
      '${_get(ts.isEmpty ? null : ts[0], 'areas.areas.0.weatherCodes.0') ?? ''}');
  final timeSeries = ts.length > 2 ? ts[2] as Map<String, dynamic> : null;
  final defs = (timeSeries?['timeDefines'] as List?) ?? const [];
  final zoneTemperatures =
      (_get(timeSeries, 'areas.areas.0.temps') as List?) ?? const [];
  /* readings: 0 h gives the minimum of the day, 9 h the maximum
     ( Japan hours ) */
  final perDay = <String, Map<String, double>>{};
  for (var j = 0; j < defs.length && j < zoneTemperatures.length; j++) {
    final value = double.tryParse('${zoneTemperatures[j]}');
    if (value == null) continue;
    final def = defs[j] as String;
    final day = def.substring(0, 10);
    final hh = def.length > 12 ? int.tryParse(def.substring(11, 13)) : null;
    final e = perDay.putIfAbsent(day, () => <String, double>{});
    if (hh == 9) {
      e['max'] = value;
    } else if (hh == 0) {
      e['min'] = value;
    }
  }
  final japanNow = DateTime.now().toUtc().add(const Duration(hours: 9));
  final day1 = japanNow.toString().substring(0, 10);
  final day2 =
      japanNow.add(const Duration(days: 1)).toString().substring(0, 10);
  var tmin = perDay[day1]?['min'] ??
      (zoneTemperatures.length > 1
          ? double.tryParse('${zoneTemperatures[1]}') ?? 0
          : 0.0);
  var tmax = perDay[day1]?['max'] ??
      (zoneTemperatures.isNotEmpty
          ? double.tryParse('${zoneTemperatures[0]}') ?? 0
          : 0.0);
  final tmin2 = perDay[day2]?['min'] ??
      (zoneTemperatures.length > 2
          ? double.tryParse('${zoneTemperatures[2]}') ?? tmin
          : tmin);
  final tmax2 = perDay[day2]?['max'] ??
      (zoneTemperatures.length > 3
          ? double.tryParse('${zoneTemperatures[3]}') ?? tmax
          : tmax);
  /* day and night interpolation: estimate of the current temperature */
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
  return WeatherReading(_jmaCode(weatherCode ?? -1), temp, tmax, tmin, tmax2, tmin2);
}

const _nwsRules = <List<Object>>[
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

int _nwsCode(String description) {
  final d = description.toLowerCase();
  for (final rule in _nwsRules) {
    if (d.contains(rule[0] as String)) return rule[1] as int;
  }
  return 3;
}

Future<WeatherReading> _loadNws(WeatherCity v) async {
  final p = await _json(Uri.parse(
      'https://api.weather.gov/points/${v.lat.toStringAsFixed(4)},${v.lon.toStringAsFixed(4)}'));
  final url = _get(p, 'properties.forecastHourly') as String?;
  if (url == null) throw const HttpException('nws');
  final f = await _json(Uri.parse(url));
  final periods = _get(f, 'properties.periods') as List;
  if (periods.isEmpty) throw const HttpException('nws');
  final first = periods.first as Map<String, dynamic>;
  /* min and max per local date of the periods */
  final days = <String, List<double>>{};
  for (final e in periods) {
    final m = e as Map<String, dynamic>;
    final day = (m['startTime'] as String).substring(0, 10);
    final value = double.tryParse('${m['temperature']}') ?? 0;
    final minmax = days.putIfAbsent(day, () => [value, value]);
    if (value < minmax[0]) minmax[0] = value;
    if (value > minmax[1]) minmax[1] = value;
  }
  final keys = days.keys.toList()..sort();
  if (keys.length < 2) throw const HttpException('nws');
  return WeatherReading(
      _nwsCode((first['shortForecast'] as String?) ?? ''),
      double.tryParse('${first['temperature']}') ?? 0,
      days[keys[0]]![1],
      days[keys[0]]![0],
      days[keys[1]]![1],
      days[keys[1]]![0]);
}

const _bomToWmo = <String, int>{
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

Future<WeatherReading> _loadBom(WeatherCity v) async {
  final s = await _json(Uri.parse(
      'https://api.weather.bom.gov.au/v1/locations?search=${Uri.encodeComponent(v.name)}'));
  final g = _get(s, 'data.0') as Map<String, dynamic>?;
  if (g == null) throw const HttpException('bom');
  final f = await _json(Uri.parse(
      'https://api.weather.bom.gov.au/v1/locations/${g['geohash']}/forecasts/daily'));
  final d0 = _get(f, 'data.0') as Map<String, dynamic>;
  final d1 = _get(f, 'data.1') as Map<String, dynamic>;
  final temp = (_get(d0, 'now.temp_now') as num?)?.toDouble() ??
      (((d0['temp_min'] as num) + (d0['temp_max'] as num)) / 2);
  return WeatherReading(
      _bomToWmo[d0['icon_descriptor'] as String? ?? ''] ?? 3,
      temp,
      (d0['temp_max'] as num).toDouble(),
      (d0['temp_min'] as num).toDouble(),
      (d1['temp_max'] as num).toDouble(),
      (d1['temp_min'] as num).toDouble());
}

const _hkoToWmo = <int, int>{
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

Future<WeatherReading> _loadHko(WeatherCity v) async {
  const base = 'https://data.weather.gov.hk/weatherAPI/opendata/weather.php';
  final f = await _json(Uri.parse('$base?dataType=fnd&lang=en'));
  final d0 = _get(f, 'weatherForecast.0') as Map<String, dynamic>;
  final d1 = _get(f, 'weatherForecast.1') as Map<String, dynamic>;
  var code = _hkoToWmo[int.tryParse('${d0['ForecastIcon']}') ?? -1] ?? 3;
  final r = await _json(Uri.parse('$base?dataType=rhrread&lang=en'));
  var temp = 0.0;
  final series = _get(r, 'temperature.data') as List?;
  for (final e in series ?? const []) {
    if ((e as Map<String, dynamic>)['place'] == 'Hong Kong Observatory') {
      temp = (e['value'] as num).toDouble();
    }
  }
  final min0 = (_get(d0, 'forecastMintemp.value') as num).toDouble();
  final max0 = (_get(d0, 'forecastMaxtemp.value') as num).toDouble();
  final min1 = (_get(d1, 'forecastMintemp.value') as num).toDouble();
  final max1 = (_get(d1, 'forecastMaxtemp.value') as num).toDouble();
  /* the temperature of the Observatory seat is missing: average of the
     extremes of the day */
  if (temp == 0.0) temp = (min0 + max0) / 2;
  /* icon of the current reading if available, otherwise the forecast one */
  final readingIcon = _hkoToWmo[((_get(r, 'icon.0') as num?) ?? -1).toInt()];
  if (readingIcon != null) code = readingIcon;
  return WeatherReading(code, temp, max0, min0, max1, min1);
}

/* orchestrator: the requested source, then Open-Meteo, then wttr.in as
   a fallback */
Future<WeatherReading> loadWeather(WeatherCity v, String source) async {
  final loaders = <String, Future<WeatherReading> Function(WeatherCity)>{
    'meteofrance': (v2) => _loadOpenMeteo(v2, 'meteofrance'),
    'metno': _loadMetno,
    'ipma': _loadIpma,
    'jma': _loadJma,
    'nws': _loadNws,
    'bom': _loadBom,
    'hko': _loadHko,
    'wttr': _loadWttr,
  };
  Object? last;
  for (final s in [source, 'open-meteo', 'wttr']) {
    try {
      if (s == 'open-meteo') return await _loadOpenMeteo(v, 'forecast');
      final f = loaders[s];
      if (f != null) return await f(v);
    } catch (e) {
      last = e;
    }
  }
  throw last ?? const HttpException('meteo');
}

/* ---------------- the screen ---------------- */

class WeatherScreen extends StatefulWidget {
  final Translator trad;
  const WeatherScreen(this.trad, {super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final _search = TextEditingController();
  List<WeatherCity>? _cities;
  int _current = 0;
  final Map<String, WeatherReading> _readings = {};
  final Map<String, String> _errors = {};
  bool _busy = false;
  List<WeatherCity>? _suggestions;

  @override
  void initState() {
    super.initState();
    readCities().then((v) {
      if (mounted) {
        setState(() => _cities = v);
        _loadCurrent();
      }
    });
  }

  WeatherCity get city => _cities == null
      ? defaultCities.first
      : _cities![_current.clamp(0, _cities!.length - 1)];

  Future<void> _loadCurrent() async {
    if (_cities == null) return;
    final v = city;
    if (_readings.containsKey(v.key())) return;
    setState(() => _busy = true);
    try {
      final r = await loadWeather(v, nationalSource(v.country));
      if (mounted) setState(() => _readings[v.key()] = r);
    } catch (_) {
      if (mounted) {
        setState(() => _errors[v.key()] = widget.trad('meteo-erreur'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _searchCity(String q) async {
    if (q.trim().length < 2) return;
    try {
      final r = await http.get(Uri.parse(
          'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(q.trim())}&count=8&language=fr&format=json'));
      final d = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      final res = (d['results'] as List?) ?? const [];
      final found = <WeatherCity>[];
      for (final e in res) {
        final j = e as Map<String, dynamic>;
        found.add(WeatherCity(
            (j['name'] as String?) ?? '',
            j['country_code'] as String?,
            (j['latitude'] as num).toDouble(),
            (j['longitude'] as num).toDouble()));
      }
      if (mounted) setState(() => _suggestions = found);
    } catch (_) {}
  }

  Future<void> _add(WeatherCity v) async {
    final cities = [...?_cities, v];
    await writeCities(cities);
    setState(() {
      _cities = cities;
      _current = cities.length - 1;
      _suggestions = null;
      _search.clear();
    });
    _loadCurrent();
  }

  Future<void> _remove(int i) async {
    final cities = [..._cities!..removeAt(i)];
    await writeCities(cities);
    setState(() {
      _cities = cities;
      _current = 0;
    });
  }

  String _sunriseSunset() {
    final now = DateTime.now();
    final sr = sunriseSunset(city.lat, city.lon, now.toUtc());
    String time(DateTime? d) =>
        d == null ? '—' : d.toLocal().toString().substring(11, 16);
    return '↑ ${time(sr[0])}   ↓ ${time(sr[1])}';
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.trad;
    if (_cities == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final reading = _readings[city.key()];
    final info = reading == null ? null : wmoInfo(reading.code);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (var i = 0; i < _cities!.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InputChip(
                  label: Text(_cities![i].name),
                  selected: i == _current,
                  onSelected: (_) {
                    setState(() {
                      _current = i;
                      _loadCurrent();
                    });
                  },
                  onDeleted: () => _remove(i),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _search,
        decoration: InputDecoration(
          labelText: t('meteo-chercher'),
          isDense: true,
          suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _searchCity(_search.text)),
        ),
        onSubmitted: _searchCity,
      ),
      if (_suggestions != null && _suggestions!.isNotEmpty) ...[
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final s in _suggestions!)
              ActionChip(
                  label: Text('${s.name} (${s.country ?? '?'})'),
                  onPressed: () => _add(s)),
          ],
        ),
      ],
      const SizedBox(height: 12),
      if (_busy) const CircularProgressIndicator(),
      if (reading != null) ...[
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
                    Text('${reading.temp.toStringAsFixed(0)} °C',
                        style: const TextStyle(fontSize: 26)),
                    Text(
                        '${info[0]} · max ${reading.max.toStringAsFixed(0)} ° · min ${reading.min.toStringAsFixed(0)} °'),
                    Text(
                        '${t('demain')} : max ${reading.max2.toStringAsFixed(0)} ° · min ${reading.min2.toStringAsFixed(0)} °'),
                    const SizedBox(height: 4),
                    Text(_sunriseSunset()),
                  ]),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Text('${t('source')} : ${_sources[nationalSource(city.country)]}',
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
      if (_errors[city.key()] != null)
        Text(_errors[city.key()]!,
            style: const TextStyle(color: Colors.red, fontSize: 13)),
    ]);
  }
}