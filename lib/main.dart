/* Lestang Outils, cross-platform application: the card registry, light or
   dark theme, language of choice, card order of choice.
   Flutter + embedded SQLite. SPDX-License-Identifier: MIT. */
import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:io' show File, Platform;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'card_registry.dart';
import 'conj/conjugation_icons.dart';
import 'conj/conjugation_screen.dart';
import 'l10n.dart';
import 'maps/geo_maps.dart';
import 'screens/info.dart';
import 'screens/password.dart';
import 'screens/pdf.dart';
import 'screens/search.dart';
import 'screens/settings.dart';
import 'screens/shortcuts.dart';
import 'screens/weather.dart';

void main() => runApp(const LestangOutilsApp());

/* the background isolates the app spawned ( none today ): the status
   bar counts the main isolate plus this counter, so a future worker
   shows up in the foot of the window as soon as it runs */
class AppWorkers {
  static int spawned = 0;
}

/* the banner gradient of the web ( PATCH213 of styles.css ): the blue
   family #2563eb, #3b82f6 then #60a5fa on the diagonal, the white text
   stays readable on it like on the site */
const appGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xff2563eb), Color(0xff3b82f6), Color(0xff60a5fa)],
    stops: [0.0, 0.4, 1.0]);

/* the light blue background of the body, like the site: the surface of
   the two windows fades on the diagonal through the blue family of
   PATCH213 ( blue-50 to blue-200 in the light theme, three navy blues
   in the dark one ) */
const _bgLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xffeff6ff), Color(0xffdbeafe), Color(0xffbfdbfe)]);
const _bgDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xff101c33), Color(0xff16233f), Color(0xff1b2a4a)]);

/* the app bar of the two windows wears the gradient of the web */
PreferredSizeWidget gradientAppBar(String title) => AppBar(
      title: Text(title),
      flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: appGradient)),
      foregroundColor: Colors.white,
    );

class LestangOutilsApp extends StatefulWidget {
  const LestangOutilsApp({super.key});

  @override
  State<LestangOutilsApp> createState() => _LestangOutilsAppState();
}

class _LestangOutilsAppState extends State<LestangOutilsApp> {
  String _language = 'fr';
  AppThemeMode _theme = AppThemeMode.system;
  int _page = 0;
  List<String> _order = cardKeys;

  static const _icons = <String, IconData>{
    'conj-fr': Icons.tab,
    'conj-en': Icons.translate,
    'conj-es': Icons.translate,
    'conj-de': Icons.translate,
    'conj-it': Icons.translate,
    'conj-pt': Icons.translate,
    'conj-pl': Icons.translate,
    'conj-cs': Icons.translate,
    'conj-ro': Icons.translate,
    'france': Icons.map,
    'union': Icons.public,
    'monde': Icons.terrain,
    'météo': Icons.wb_sunny,
    'pdf': Icons.compress,
    'recherche': Icons.search,
    'raccourcis': Icons.bookmarks,
    'motdepasse': Icons.key,
    'réglages': Icons.settings,
    'infos': Icons.info,
  };

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final l = await readLanguage();
    final t = await readTheme();
    final order = await readOrder();
    if (mounted) {
      setState(() {
        _language = l;
        _theme = t;
        _order = order;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final trad = Translator(_language);
    /* the map dialogs and the status bar read this global language to
       translate their own labels */
    appLanguage = _language;
    final light = _theme == AppThemeMode.light ||
        (_theme == AppThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.light);
    return MaterialApp(
      title: 'Lestang Outils',
      /* the blue family of the web replaces the purple of the default
         Material 3 seed: every chip, slider, switch and button of the
         application derives from the light blue #3b82f6 ( PATCH213 ),
         in the light theme like in the dark one */
      theme: light
          ? ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xff3b82f6),
                  brightness: Brightness.light))
          : ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xff3b82f6),
                  brightness: Brightness.dark)),
      home: Scaffold(
        appBar: gradientAppBar(trad('titre')),
        bottomNavigationBar: const StatusBar(),
        body: DecoratedBox(
            decoration: BoxDecoration(gradient: light ? _bgLight : _bgDark),
            child: Row(children: [
          NavigationRail(
            selectedIndex: _page.clamp(0, _order.length - 1),
            onDestinationSelected: (i) => setState(() => _page = i),
            labelType: NavigationRailLabelType.selected,
            minWidth: 56,
            groupAlignment: -1,
            destinations: [
              for (final c in _order)
                NavigationRailDestination(
                  /* conjugation : a coloured icon per language, with the
                     flag and the two letters ; other cards : icon */
                  icon: c.startsWith('conj-')
                      ? conjugIcon(c.substring(5))
                      : Icon(_icons[c] ?? Icons.extension),
                  label: Text(trad(c)),
                ),
            ],
          ),
          const VerticalDivider(width: 0),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: _currentPage(trad),
            ),
          ),
        ])),
      ),
    );
  }

  Widget _currentPage(Translator trad) {
    if (_page >= _order.length) _page = 0;
    final key = _order[_page];
    switch (key) {
      case 'conj-fr':
      case 'conj-en':
      case 'conj-es':
      case 'conj-de':
      case 'conj-it':
      case 'conj-pt':
      case 'conj-pl':
      case 'conj-cs':
      case 'conj-ro':
        final language = key.substring(5);
        /* one key per language : without it, Flutter reuses the state of
           the screen of another language ( conjugation set already loaded ) */
        return ConjugationScreen(language, trad,
            key: ValueKey('conj-$language'));
      case 'france':
      case 'union':
      case 'monde':
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(trad(key),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(width: 10),
            IconButton(
              tooltip: trad('plein-ecran'),
              icon: const Icon(Icons.fullscreen),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Scaffold(
                          appBar: gradientAppBar(trad(key)),
                          bottomNavigationBar: const StatusBar(),
                          body: DecoratedBox(
                              decoration: BoxDecoration(
                                  gradient:
                                      Theme.of(context).brightness ==
                                              Brightness.light
                                          ? _bgLight
                                          : _bgDark),
                              child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: MapScreen(key,
                                      key: ValueKey(key))))))),
            ),
          ]),
          const SizedBox(height: 10),
          Expanded(child: MapScreen(key, key: ValueKey(key))),
        ]);
      case 'météo':
        return WeatherScreen(trad);
      case 'pdf':
        return PdfScreen(trad);
      case 'recherche':
        return SearchScreen(trad);
      case 'raccourcis':
        return ShortcutsScreen(trad);
      case 'motdepasse':
        return PasswordScreen(trad);
      case 'réglages':
        return SettingsScreen(_language, _theme, _order, (l) async {
          final p = await SharedPreferences.getInstance();
          await p.setString('langue', l);
          setState(() => _language = l);
        }, (t) async {
          final p = await SharedPreferences.getInstance();
          await p.setString(
              'theme',
              t == AppThemeMode.light
                  ? 'clair'
                  : t == AppThemeMode.dark
                      ? 'sombre'
                      : 'systeme');
          setState(() => _theme = t);
        }, (order) async {
          await writeOrder(order);
          setState(() {
            _order = order;
            _page = 0;
          });
        });
      case 'infos':
        return InfoScreen(trad);
    }
    return const SizedBox.shrink();
  }
}

/* the status bar of the foot of the window: the resident memory of the
   process ( currentRss, refreshed every two seconds ) and the number
   of workers, the main isolate plus every background isolate the app
   spawned; on the web target the VM does not expose the memory, the
   bar shows the workers alone */
class StatusBar extends StatefulWidget {
  const StatusBar({super.key});

  @override
  State<StatusBar> createState() => _StatusBarState();
}

/* PROCESS_MEMORY_COUNTERS of the Win32 API: cb, page faults, then sizes. */
final class _ProcessMemoryCounters extends ffi.Struct {
  @ffi.Uint32()
  external int cb;
  @ffi.Uint32()
  external int pageFaultCount;
  @ffi.IntPtr()
  external int peakWorkingSetSize;
  @ffi.IntPtr()
  external int workingSetSize;
  @ffi.IntPtr()
  external int quotaPeakPagedPoolUsage;
  @ffi.IntPtr()
  external int quotaPagedPoolUsage;
  @ffi.IntPtr()
  external int quotaPeakNonPagedPoolUsage;
  @ffi.IntPtr()
  external int quotaNonPagedPoolUsage;
  @ffi.IntPtr()
  external int pagefileUsage;
  @ffi.IntPtr()
  external int peakPagefileUsage;
}

/* Working set of this process on Windows: the Windows front end of Flutter
   does not expose dart:developer's ProcessInfo, so psapi is called. */
int _windowsRss() {
  final p = ffi.DynamicLibrary.open('msvcrt.dll')
      .lookupFunction<
          ffi.Pointer<ffi.Void> Function(ffi.IntPtr),
          ffi.Pointer<ffi.Void> Function(int)>('malloc')(
          ffi.sizeOf<_ProcessMemoryCounters>())
      .cast<_ProcessMemoryCounters>();
  final free = ffi.DynamicLibrary.open('msvcrt.dll').lookupFunction<
      ffi.Void Function(ffi.Pointer<ffi.Void>),
      void Function(ffi.Pointer<ffi.Void>)>('free');
  final getCurrentProcess = ffi.DynamicLibrary.open('Kernel32.dll')
      .lookupFunction<ffi.Pointer<ffi.Void> Function(),
          ffi.Pointer<ffi.Void> Function()>('GetCurrentProcess');
  var getInfo = ffi.DynamicLibrary.open('Psapi.dll').lookupFunction<
      ffi.Int32 Function(ffi.Pointer<ffi.Void>,
          ffi.Pointer<_ProcessMemoryCounters>, ffi.Uint32),
      int Function(ffi.Pointer<ffi.Void>, ffi.Pointer<_ProcessMemoryCounters>,
          int)>('GetProcessMemoryInfo');
  p.ref.cb = ffi.sizeOf<_ProcessMemoryCounters>();
  var rss = 0;
  if (getInfo(getCurrentProcess(), p, p.ref.cb) != 0) {
    rss = p.ref.workingSetSize;
  }
  free(p.cast());
  return rss;
}

/* Resident memory of this process, in bytes, 0 when unknown. */
int _processRss() {
  try {
    if (Platform.isWindows) {
      return _windowsRss();
    }
    if (Platform.isLinux || Platform.isAndroid) {
      final statm = File('/proc/self/statm').readAsStringSync().split(' ');
      if (statm.length > 1) return int.parse(statm[1]) * 4096;
    }
  } catch (_) {
    /* this platform does not expose its memory */
  }
  return 0;
}

class _StatusBarState extends State<StatusBar> {
  Timer? _timer;
  int _rss = 0;
  int _workers = 1;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _refresh() {
    var rss = 0;
    var workers = 1 + AppWorkers.spawned;
    rss = _processRss();
    if (!mounted) return;
    if (rss == _rss && workers == _workers) return;
    setState(() {
      _rss = rss;
      _workers = workers;
    });
  }

  @override
  Widget build(BuildContext context) {
    final small =
        Theme.of(context).textTheme.bodySmall?.color ?? const Color(0xff495057);
    /* the labels of the bar live in the glossary, like the screens */
    final text = _rss > 0
        ? '${trad('stat-ram')} : ${(_rss / 1048576).toStringAsFixed(0)} Mo · ${trad('stat-workers')} : $_workers'
        : '${trad('stat-workers')} : $_workers';
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor))),
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
      child: Text(text,
          style: TextStyle(fontSize: 11, color: small),
          textAlign: TextAlign.left),
    );
  }
}
