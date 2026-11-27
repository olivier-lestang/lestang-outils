/* The clocks of the marked cities of the world map: the real IANA
   time zones of the web ( WM_TZ by country, WM_TZ_CITY overrides and
   longitude bands for the multi-zone countries of
   js/monde/villes-marquees.js ), resolved by the timezone package at
   the chosen instant, daylight saving included; the estimate from
   the longitude remains as a fallback, like on the web.
   SPDX-License-Identifier: MIT. */
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'world_data.dart';

bool _tzReady = false;

/* the IANA zone of a city: the city overrides of the web first, then
   the zone of the country; the multi-zone countries follow their
   longitude bands, exactly the wmCityTZ of the web */
String? cityZone(String name, String cc, double lon) {
  final override = worldTzCity[name];
  if (override != null) return override;
  final entry = worldTz[cc];
  if (entry == null) return null;
  if (entry is String) return entry;
  final bands = entry as List;
  if (bands.isEmpty) return null;
  var zone = (bands[bands.length - 1] as List)[1] as String;
  final l = ((lon + 540) % 360) - 180;
  for (final b in bands) {
    final band = b as List;
    if (l >= (band[0] as num).toDouble()) {
      zone = band[1] as String;
    } else {
      break;
    }
  }
  return zone;
}

/* the UTC offset in minutes of an IANA zone at a given instant,
   daylight saving included; null when the zone is unknown to the
   database */
int? zoneOffsetMinutes(String zone, DateTime instant) {
  try {
    if (!_tzReady) {
      tzdata.initializeTimeZones();
      _tzReady = true;
    }
    final loc = tz.getLocation(zone);
    /* the offset comes from a TZDateTime of the zone: the API of
       the package exposes no offset method on the location itself */
    final dt = tz.TZDateTime.fromMillisecondsSinceEpoch(
        loc, instant.toUtc().millisecondsSinceEpoch);
    return dt.timeZoneOffset.inMinutes;
  } catch (_) {
    return null;
  }
}

/* the local clock of a city at a given instant: the time, the UTC
   offset in minutes and whether the offset was only estimated from
   the longitude ( the fallback of the web ) */
class CityClock {
  final DateTime time;
  final int offset;
  final bool estimated;
  CityClock(this.time, this.offset, this.estimated);
}

CityClock cityClock(String name, String cc, double lon, DateTime instant) {
  final zone = cityZone(name, cc, lon);
  final off = zone == null ? null : zoneOffsetMinutes(zone, instant);
  final minutes = off ?? ((lon / 15).round() * 60);
  return CityClock(
      instant.toUtc().add(Duration(minutes: minutes)), minutes, off == null);
}

/* the GMT label of an offset in minutes, like the web table:
   GMT+2, GMT+5.5, GMT-3 */
String gmtLabel(int offsetMinutes) {
  final h = offsetMinutes / 60.0;
  final a = h.abs();
  final s = a % 1 == 0 ? a.toStringAsFixed(0) : a.toStringAsFixed(1);
  return 'GMT${h < 0 ? '-' : '+'}$s';
}