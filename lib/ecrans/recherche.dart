/* Recherche : moteurs web, IA, cartographie, reseaux sociaux, dictionnaires
   et encyclopedies, tous parametrables par {q}. Portage de
   js/outils/recherche.js.
   SPDX-License-Identifier : MIT. */
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n.dart';

class MoteurRecherche {
  final String id;
  final String groupe;
  final String nom;
  final String patron;
  const MoteurRecherche(this.id, this.groupe, this.nom, this.patron);
}

/* l edition Wikipedia suit la langue de l interface */
const moteurs = <MoteurRecherche>[
  MoteurRecherche(
      'bing', 'moteur', 'Bing', 'https://www.bing.com/search?q={q}'),
  MoteurRecherche('baidu', 'moteur', 'Baidu', 'https://www.baidu.com/s?wd={q}'),
  MoteurRecherche('brave', 'moteur', 'Brave Search',
      'https://search.brave.com/search?q={q}'),
  MoteurRecherche(
      'duckduckgo', 'moteur', 'DuckDuckGo', 'https://duckduckgo.com/?q={q}'),
  MoteurRecherche(
      'ecosia', 'moteur', 'Ecosia', 'https://www.ecosia.org/search?q={q}'),
  MoteurRecherche(
      'google', 'moteur', 'Google', 'https://www.google.com/search?q={q}'),
  MoteurRecherche('lilo', 'moteur', 'Lilo', 'https://search.lilo.org/?q={q}'),
  MoteurRecherche('qwant', 'moteur', 'Qwant', 'https://www.qwant.com/?q={q}'),
  MoteurRecherche(
      'yahoo', 'moteur', 'Yahoo', 'https://search.yahoo.com/search?p={q}'),
  MoteurRecherche('naver', 'moteur', 'Naver',
      'https://search.naver.com/search.naver?query={q}'),
  MoteurRecherche(
      'yandex', 'moteur', 'Yandex', 'https://yandex.ru/search/?text={q}'),
  MoteurRecherche('chatgpt', 'ia', 'ChatGPT', 'https://chatgpt.com/?q={q}'),
  MoteurRecherche('claude', 'ia', 'Claude', 'https://claude.ai/new?q={q}'),
  MoteurRecherche(
      'copilot', 'ia', 'Copilot', 'https://copilot.microsoft.com/?q={q}'),
  MoteurRecherche(
      'mistral', 'ia', 'Mistral AI', 'https://chat.mistral.ai/chat?q={q}'),
  MoteurRecherche('perplexity', 'ia', 'Perplexity',
      'https://www.perplexity.ai/search?q={q}'),
  MoteurRecherche('qwen', 'ia', 'Qwen', 'https://chat.qwen.ai/?q={q}'),
  MoteurRecherche(
      'deepseek', 'ia', 'DeepSeek', 'https://chat.deepseek.com/?q={q}'),
  MoteurRecherche('gmaps', 'carto', 'Google Maps',
      'https://www.google.com/maps/search/{q}'),
  MoteurRecherche(
      'amaps', 'carto', 'Apple Maps', 'https://maps.apple.com/?q={q}'),
  MoteurRecherche(
      'bmaps', 'carto', 'Baidu Maps', 'https://map.baidu.com/search/{q}'),
  MoteurRecherche('osm', 'carto', 'OpenStreetMap',
      'https://www.openstreetmap.org/search?query={q}'),
  MoteurRecherche(
      'bingmaps', 'carto', 'Bing Maps', 'https://www.bing.com/maps?q={q}'),
  MoteurRecherche(
      'navermaps', 'carto', 'Naver Maps', 'https://map.naver.com/p/search/{q}'),
  MoteurRecherche(
      'yandexmaps', 'carto', 'Yandex Maps', 'https://yandex.ru/maps/?text={q}'),
  MoteurRecherche(
      'mapy', 'carto', 'Mapy.com', 'https://mapy.com/zakladni?q={q}'),
  MoteurRecherche('cartesgouv', 'carto', 'Cartes.gouv.fr',
      'https://cartes.gouv.fr/rechercher-une-donnee/search?q={q}'),
  MoteurRecherche('mappy', 'carto', 'Mappy', 'https://fr.mappy.com/?q={q}'),
  MoteurRecherche(
      'here', 'carto', 'Here Maps', 'https://wego.here.com/search/{q}'),
  MoteurRecherche(
      'tomtom', 'carto', 'TomTom', 'https://plan.tomtom.com/?q={q}'),
  MoteurRecherche('facebook', 'social', 'Facebook',
      'https://www.facebook.com/search/top?q={q}'),
  MoteurRecherche(
      'tiktok', 'social', 'TikTok', 'https://www.tiktok.com/search?q={q}'),
  MoteurRecherche('youtube', 'social', 'YouTube',
      'https://www.youtube.com/results?search_query={q}'),
  MoteurRecherche('x', 'social', 'X', 'https://x.com/search?q={q}'),
  MoteurRecherche('instagram', 'social', 'Instagram',
      'https://www.instagram.com/explore/tags/{q}/'),
  MoteurRecherche(
      'vk', 'social', 'VKontakte', 'https://vk.com/search?c[q]={q}'),
  MoteurRecherche(
      'weibo', 'social', 'Weibo', 'https://s.weibo.com/weibo?q={q}'),
  MoteurRecherche(
      'douyin', 'social', 'Douyin', 'https://www.douyin.com/search/{q}'),
  MoteurRecherche('universalis', 'encyclopedie', 'Universalis',
      'https://www.universalis.fr/recherche/l/1/q/{q}'),
  MoteurRecherche('wikipedia', 'encyclopedie', 'Wikipédia',
      'https://{wl}.wikipedia.org/w/index.php?search={q}'),
  MoteurRecherche(
      'cnrtl',
      'dictionnaire',
      'CNRTL \u2014 Trésor de la langue française',
      'https://www.cnrtl.fr/definition/{q}'),
  MoteurRecherche('larousse', 'dictionnaire', 'Larousse',
      'https://www.larousse.fr/dictionnaires/francais/{q}'),
  MoteurRecherche('mw', 'dictionnaire', 'Merriam-Webster',
      'https://www.merriam-webster.com/dictionary/{q}'),
  MoteurRecherche(
      'zdic', 'dictionnaire', '汉典 Zdic', 'https://www.zdic.net/hans/{q}'),
  MoteurRecherche('wiktionary', 'dictionnaire', 'Wiktionnaire',
      'https://{wt}.wiktionary.org/w/index.php?search={q}'),
  MoteurRecherche('linguee', 'multilingue', 'Linguee',
      'https://www.linguee.fr/francais-anglais/search?query={q}'),
  MoteurRecherche('wordreference', 'multilingue', 'WordReference',
      'https://www.wordreference.com/fren/{q}'),
];

const _groupes = <String, String>{
  'moteur': 'Moteur de recherche',
  'carto': 'Cartographie',
  'ia': 'Moteur IA',
  'social': 'Réseau social',
  'dictionnaire': 'Dictionnaire monolingue',
  'multilingue': 'Dictionnaire multilingue',
  'encyclopedie': 'Encyclopédie',
};

class EcranRecherche extends StatefulWidget {
  final Traducteur trad;
  const EcranRecherche(this.trad, {super.key});

  @override
  State<EcranRecherche> createState() => _EcranRechercheState();
}

class _EcranRechercheState extends State<EcranRecherche> {
  final _champ = TextEditingController();
  Set<String>? _choisis;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      final crus = p.getStringList('recherche-moteurs');
      if (mounted) {
        setState(() => _choisis =
            crus == null ? {'google', 'gmaps', 'wikipedia'} : crus.toSet());
      }
    });
  }

  Future<void> _basculer(String id) async {
    final c = {...?_choisis};
    if (!c.add(id)) c.remove(id);
    setState(() => _choisis = c);
    final p = await SharedPreferences.getInstance();
    await p.setStringList('recherche-moteurs', c.toList());
  }

  Future<void> _lancer(MoteurRecherche m, String q) async {
    if (q.trim().isEmpty) return;
    var patron = m.patron
        .replaceAll('{wl}', widget.trad.langue)
        .replaceAll('{wt}', widget.trad.langue)
        .replaceAll('{q}', Uri.encodeComponent(q.trim()));
    if (m.id == 'google') {
      /* les moteurs en {q} encodent deja ; ceux en chemin sont percent-encodes par Uri.parse */
      patron = m.patron.replaceFirst('{q}', Uri.encodeComponent(q.trim()));
    }
    final u = Uri.tryParse(patron);
    if (u != null && await canLaunchUrl(u))
      await launchUrl(u, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.trad;
    if (_choisis == null)
      return const Center(child: CircularProgressIndicator());
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        controller: _champ,
        decoration: InputDecoration(
          labelText: t('recherche-chercher'),
          suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                final q = _champ.text;
                if (moteurs.any((m) => m.id == 'google')) {
                  _lancer(moteurs.firstWhere((m) => m.id == 'google'), q);
                }
              }),
        ),
        onSubmitted: (q) {
          if (_choisis!.contains('google')) {
            _lancer(moteurs.firstWhere((m) => m.id == 'google'), q);
          } else if (_choisis!.isNotEmpty) {
            final premierMot =
                moteurs.firstWhere((m) => _choisis!.contains(m.id));
            _lancer(premierMot, q);
          }
        },
      ),
      const SizedBox(height: 14),
      for (final entree in _groupes.entries) ...[
        if (_choisis!.any((id) =>
            moteurs.any((m) => m.id == id && m.groupe == entree.key))) ...[
          Text(entree.value,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in moteurs) ...[
                if (_choisi(m))
                  ActionChip(
                    label: Text(m.nom),
                    onPressed: () => _lancer(m, _champ.text),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 14),
        ],
      ],
      Row(children: [
        Text(t('editer'), style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 14),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final m in moteurs)
                FilterChip(
                  label: Text(m.nom, style: const TextStyle(fontSize: 11)),
                  selected: _choisi(m),
                  onSelected: (_) => _basculer(m.id),
                ),
            ],
          ),
        ),
      ]),
    ]);
  }

  bool _choisi(MoteurRecherche m) => _choisis!.contains(m.id);
}
