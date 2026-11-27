/* Lestang Outils, cross-platform application: the card registry, light or
   dark theme, language of choice, card order of choice.
   Flutter + embedded SQLite. SPDX-License-Identifier: MIT. */
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
    final light = _theme == AppThemeMode.light ||
        (_theme == AppThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.light);
    return MaterialApp(
      title: 'Lestang Outils',
      theme: light
          ? ThemeData(brightness: Brightness.light, useMaterial3: true)
          : ThemeData(brightness: Brightness.dark, useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(title: Text(trad('titre'))),
        body: Row(children: [
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
        ]),
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
              tooltip: 'Plein écran',
              icon: const Icon(Icons.fullscreen),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Scaffold(
                          appBar: AppBar(title: Text(trad(key))),
                          body: Padding(
                              padding: const EdgeInsets.all(10),
                              child: MapScreen(key, key: ValueKey(key)))))),
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