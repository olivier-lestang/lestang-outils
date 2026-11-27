/* Lestang Outils, application multiplateformes : le registre des cartes,
   thème clair ou sombre, langue au choix, ordre des cartes au choix.
   Flutter + SQLite embarquee. SPDX-License-Identifier : MIT. */
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cartes/cartes_geo.dart';
import 'conj/ecran_conjugaison.dart';
import 'ecrans/infos.dart';
import 'ecrans/meteo.dart';
import 'ecrans/motdepasse.dart';
import 'ecrans/pdf.dart';
import 'ecrans/raccourcis.dart';
import 'ecrans/recherche.dart';
import 'ecrans/reglages.dart';
import 'l10n.dart';
import 'registre.dart';

void main() => runApp(const AppLestangOutils());

class AppLestangOutils extends StatefulWidget {
  const AppLestangOutils({super.key});

  @override
  State<AppLestangOutils> createState() => _AppLestangOutilsState();
}

class _AppLestangOutilsState extends State<AppLestangOutils> {
  String _langue = 'fr';
  ModeTheme _theme = ModeTheme.systeme;
  int _page = 0;
  List<String> _ordre = clesCartes;

  static const _icones = <String, IconData>{
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
    _restaurer();
  }

  Future<void> _restaurer() async {
    final l = await lireLangue();
    final t = await lireTheme();
    final ordre = await lireOrdre();
    if (mounted) {
      setState(() {
        _langue = l;
        _theme = t;
        _ordre = ordre;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final trad = Traducteur(_langue);
    final clair = _theme == ModeTheme.clair ||
        (_theme == ModeTheme.systeme &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.light);
    return MaterialApp(
      title: 'Lestang Outils',
      theme: clair
          ? ThemeData(brightness: Brightness.light, useMaterial3: true)
          : ThemeData(brightness: Brightness.dark, useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(title: Text(trad('titre'))),
        body: Row(children: [
          NavigationRail(
            selectedIndex: _page.clamp(0, _ordre.length - 1),
            onDestinationSelected: (i) => setState(() => _page = i),
            labelType: NavigationRailLabelType.selected,
            minWidth: 56,
            groupAlignment: -1,
            destinations: [
              for (final c in _ordre)
                NavigationRailDestination(
                  icon: Icon(_icones[c] ?? Icons.extension),
                  label: Text(trad(c)),
                ),
            ],
          ),
          const VerticalDivider(width: 0),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: _pageCourante(trad),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _pageCourante(Traducteur trad) {
    if (_page >= _ordre.length) _page = 0;
    final cle = _ordre[_page];
    switch (cle) {
      case 'conj-fr':
      case 'conj-en':
      case 'conj-es':
      case 'conj-de':
      case 'conj-it':
      case 'conj-pt':
      case 'conj-pl':
      case 'conj-cs':
      case 'conj-ro':
        final langue = cle.substring(5);
        /* une cle par langue : sans elle, Flutter reutilise l'etat de
           l'ecran d'une autre langue ( jeu de conjugaison deja charge ) */
        return EcranConjugaison(langue, trad, key: ValueKey('conj-$langue'));
      case 'france':
      case 'union':
      case 'monde':
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(trad(cle),
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
                          appBar: AppBar(title: Text(trad(cle))),
                          body: Padding(
                              padding: const EdgeInsets.all(10),
                              child: EcranCarte(cle, key: ValueKey(cle))))),
            ),
          ]),
          const SizedBox(height: 10),
          Expanded(child: EcranCarte(cle, key: ValueKey(cle))),
        ]);
      case 'météo':
        return EcranMeteo(trad);
      case 'pdf':
        return EcranPdf(trad);
      case 'recherche':
        return EcranRecherche(trad);
      case 'raccourcis':
        return EcranRaccourcis(trad);
      case 'motdepasse':
        return EcranMotDePasse(trad);
      case 'réglages':
        return EcranReglages(_langue, _theme, _ordre, (l) async {
          final p = await SharedPreferences.getInstance();
          await p.setString('langue', l);
          setState(() => _langue = l);
        }, (t) async {
          final p = await SharedPreferences.getInstance();
          await p.setString(
              'theme',
              t == ModeTheme.clair
                  ? 'clair'
                  : t == ModeTheme.sombre
                      ? 'sombre'
                      : 'systeme');
          setState(() => _theme = t);
        }, (ordre) async {
          await ecrireOrdre(ordre);
          setState(() {
            _ordre = ordre;
            _page = 0;
          });
        });
      case 'infos':
        return EcranInfos(trad);
    }
    return const SizedBox.shrink();
  }
}
