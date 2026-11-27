/* Search: web engines, AI, cartography, social networks, dictionaries
   and encyclopedias, all parameterised by {q}. Port of
   js/outils/recherche.js.
   SPDX-License-Identifier: MIT. */
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n.dart';

class SearchEngine {
  final String id;
  final String group;
  final String name;
  final String pattern;
  const SearchEngine(this.id, this.group, this.name, this.pattern);
}

/* the Wikipedia edition follows the language of the interface */
const engines = <SearchEngine>[
  SearchEngine(
      'bing', 'moteur', 'Bing', 'https://www.bing.com/search?q={q}'),
  SearchEngine('baidu', 'moteur', 'Baidu', 'https://www.baidu.com/s?wd={q}'),
  SearchEngine('brave', 'moteur', 'Brave Search',
      'https://search.brave.com/search?q={q}'),
  SearchEngine(
      'duckduckgo', 'moteur', 'DuckDuckGo', 'https://duckduckgo.com/?q={q}'),
  SearchEngine(
      'ecosia', 'moteur', 'Ecosia', 'https://www.ecosia.org/search?q={q}'),
  SearchEngine(
      'google', 'moteur', 'Google', 'https://www.google.com/search?q={q}'),
  SearchEngine('lilo', 'moteur', 'Lilo', 'https://search.lilo.org/?q={q}'),
  SearchEngine('qwant', 'moteur', 'Qwant', 'https://www.qwant.com/?q={q}'),
  SearchEngine(
      'yahoo', 'moteur', 'Yahoo', 'https://search.yahoo.com/search?p={q}'),
  SearchEngine('naver', 'moteur', 'Naver',
      'https://search.naver.com/search.naver?query={q}'),
  SearchEngine(
      'yandex', 'moteur', 'Yandex', 'https://yandex.ru/search/?text={q}'),
  SearchEngine('chatgpt', 'ia', 'ChatGPT', 'https://chatgpt.com/?q={q}'),
  SearchEngine('claude', 'ia', 'Claude', 'https://claude.ai/new?q={q}'),
  SearchEngine(
      'copilot', 'ia', 'Copilot', 'https://copilot.microsoft.com/?q={q}'),
  SearchEngine(
      'mistral', 'ia', 'Mistral AI', 'https://chat.mistral.ai/chat?q={q}'),
  SearchEngine('perplexity', 'ia', 'Perplexity',
      'https://www.perplexity.ai/search?q={q}'),
  SearchEngine('qwen', 'ia', 'Qwen', 'https://chat.qwen.ai/?q={q}'),
  SearchEngine(
      'deepseek', 'ia', 'DeepSeek', 'https://chat.deepseek.com/?q={q}'),
  SearchEngine('gmaps', 'carto', 'Google Maps',
      'https://www.google.com/maps/search/{q}'),
  SearchEngine(
      'amaps', 'carto', 'Apple Maps', 'https://maps.apple.com/?q={q}'),
  SearchEngine(
      'bmaps', 'carto', 'Baidu Maps', 'https://map.baidu.com/search/{q}'),
  SearchEngine('osm', 'carto', 'OpenStreetMap',
      'https://www.openstreetmap.org/search?query={q}'),
  SearchEngine(
      'bingmaps', 'carto', 'Bing Maps', 'https://www.bing.com/maps?q={q}'),
  SearchEngine(
      'navermaps', 'carto', 'Naver Maps', 'https://map.naver.com/p/search/{q}'),
  SearchEngine(
      'yandexmaps', 'carto', 'Yandex Maps', 'https://yandex.ru/maps/?text={q}'),
  SearchEngine(
      'mapy', 'carto', 'Mapy.com', 'https://mapy.com/zakladni?q={q}'),
  SearchEngine('cartesgouv', 'carto', 'Cartes.gouv.fr',
      'https://cartes.gouv.fr/rechercher-une-donnee/search?q={q}'),
  SearchEngine('mappy', 'carto', 'Mappy', 'https://fr.mappy.com/?q={q}'),
  SearchEngine(
      'here', 'carto', 'Here Maps', 'https://wego.here.com/search/{q}'),
  SearchEngine(
      'tomtom', 'carto', 'TomTom', 'https://plan.tomtom.com/?q={q}'),
  SearchEngine('facebook', 'social', 'Facebook',
      'https://www.facebook.com/search/top?q={q}'),
  SearchEngine(
      'tiktok', 'social', 'TikTok', 'https://www.tiktok.com/search?q={q}'),
  SearchEngine('youtube', 'social', 'YouTube',
      'https://www.youtube.com/results?search_query={q}'),
  SearchEngine('x', 'social', 'X', 'https://x.com/search?q={q}'),
  SearchEngine('instagram', 'social', 'Instagram',
      'https://www.instagram.com/explore/tags/{q}/'),
  SearchEngine(
      'vk', 'social', 'VKontakte', 'https://vk.com/search?c[q]={q}'),
  SearchEngine(
      'weibo', 'social', 'Weibo', 'https://s.weibo.com/weibo?q={q}'),
  SearchEngine(
      'douyin', 'social', 'Douyin', 'https://www.douyin.com/search/{q}'),
  SearchEngine('universalis', 'encyclopedie', 'Universalis',
      'https://www.universalis.fr/recherche/l/1/q/{q}'),
  SearchEngine('wikipedia', 'encyclopedie', 'Wikipédia',
      'https://{wl}.wikipedia.org/w/index.php?search={q}'),
  SearchEngine(
      'cnrtl',
      'dictionnaire',
      'CNRTL \u2014 Trésor de la langue française',
      'https://www.cnrtl.fr/definition/{q}'),
  SearchEngine('larousse', 'dictionnaire', 'Larousse',
      'https://www.larousse.fr/dictionnaires/francais/{q}'),
  SearchEngine('mw', 'dictionnaire', 'Merriam-Webster',
      'https://www.merriam-webster.com/dictionary/{q}'),
  SearchEngine(
      'zdic', 'dictionnaire', '汉典 Zdic', 'https://www.zdic.net/hans/{q}'),
  SearchEngine('wiktionary', 'dictionnaire', 'Wiktionnaire',
      'https://{wt}.wiktionary.org/w/index.php?search={q}'),
  SearchEngine('linguee', 'multilingue', 'Linguee',
      'https://www.linguee.fr/francais-anglais/search?query={q}'),
  SearchEngine('wordreference', 'multilingue', 'WordReference',
      'https://www.wordreference.com/fren/{q}'),
];

const _groups = <String, String>{
  'moteur': 'Moteur de recherche',
  'carto': 'Cartographie',
  'ia': 'Moteur IA',
  'social': 'Réseau social',
  'dictionnaire': 'Dictionnaire monolingue',
  'multilingue': 'Dictionnaire multilingue',
  'encyclopedie': 'Encyclopédie',
};

class SearchScreen extends StatefulWidget {
  final Translator trad;
  const SearchScreen(this.trad, {super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _field = TextEditingController();
  Set<String>? _selected;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      final raw = p.getStringList('recherche-moteurs');
      if (mounted) {
        setState(() => _selected =
            raw == null ? {'google', 'gmaps', 'wikipedia'} : raw.toSet());
      }
    });
  }

  Future<void> _toggle(String id) async {
    final c = {...?_selected};
    if (!c.add(id)) c.remove(id);
    setState(() => _selected = c);
    final p = await SharedPreferences.getInstance();
    await p.setStringList('recherche-moteurs', c.toList());
  }

  Future<void> _launch(SearchEngine m, String q) async {
    if (q.trim().isEmpty) return;
    var pattern = m.pattern
        .replaceAll('{wl}', widget.trad.langue)
        .replaceAll('{wt}', widget.trad.langue)
        .replaceAll('{q}', Uri.encodeComponent(q.trim()));
    if (m.id == 'google') {
      /* the engines in {q} already encode; the path ones are
         percent-encoded by Uri.parse */
      pattern = m.pattern.replaceFirst('{q}', Uri.encodeComponent(q.trim()));
    }
    final u = Uri.tryParse(pattern);
    if (u != null && await canLaunchUrl(u))
      await launchUrl(u, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.trad;
    if (_selected == null)
      return const Center(child: CircularProgressIndicator());
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        controller: _field,
        decoration: InputDecoration(
          labelText: t('recherche-chercher'),
          suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                final q = _field.text;
                if (engines.any((m) => m.id == 'google')) {
                  _launch(engines.firstWhere((m) => m.id == 'google'), q);
                }
              }),
        ),
        onSubmitted: (q) {
          if (_selected!.contains('google')) {
            _launch(engines.firstWhere((m) => m.id == 'google'), q);
          } else if (_selected!.isNotEmpty) {
            final first =
                engines.firstWhere((m) => _selected!.contains(m.id));
            _launch(first, q);
          }
        },
      ),
      const SizedBox(height: 14),
      for (final entry in _groups.entries) ...[
        if (_selected!.any((id) =>
            engines.any((m) => m.id == id && m.group == entry.key))) ...[
          Text(entry.value,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in engines) ...[
                if (_isSelected(m))
                  ActionChip(
                    label: Text(m.name),
                    onPressed: () => _launch(m, _field.text),
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
              for (final m in engines)
                FilterChip(
                  label: Text(m.name, style: const TextStyle(fontSize: 11)),
                  selected: _isSelected(m),
                  onSelected: (_) => _toggle(m.id),
                ),
            ],
          ),
        ),
      ]),
    ]);
  }

  bool _isSelected(SearchEngine m) => _selected!.contains(m.id);
}