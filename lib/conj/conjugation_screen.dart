/* The conjugation screen: search, definition, pronominal form, the
   tinted tense table, definition with the source above each group,
   English grid.
   Port of the interface of the web conjugation modules.
   SPDX-License-Identifier: MIT. */
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database.dart' as db;
import '../l10n.dart';
import 'core.dart';
import 'engines.dart';

/* The ten translucent backgrounds of the table, web/css/styles.css .conj-tK */
const _tints = <Color>[
  Color(0x298ab4ff), // 0 present, blue
  Color(0x296fd8c9), // 1 imperfect, teal
  Color(0x2bffce7a), // 2 simple past, amber
  Color(0x26b89aff), // 3 future, violet
  Color(0x268fd88f), // 4 compound, green
  Color(0x26ff9ab6), // 5 pluperfect, pink
  Color(0x29ffb37a), // 6 past anterior, orange
  Color(0x24d68aff), // 7 future anterior, mauve
  Color(0x2bd8c9a0), // 8 past, sand
  Color(0x267ad4ff), // 9 other tense, cyan
];


class ConjugationScreen extends StatefulWidget {
  final String language; // fr, en, es, de, it, pt
  final Translator translator;
  ConjugationScreen(this.language, this.translator, {super.key});

  @override
  State<ConjugationScreen> createState() => _ConjugationScreenState();
}

class _ConjugationScreenState extends State<ConjugationScreen> {
  ConjugTables? tables;
  final _q = TextEditingController();
  List<String> _suggestions = const [];
  String _verb = '';
  bool _clitic = false;

  @override
  void initState() {
    super.initState();
    _q.addListener(_search);
    db.conjugationTables(widget.language).then((j) {
      if (!mounted) return;
      setState(() {
        tables = j;
        _verb = j.set.randomVerb();
      });
    });
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  void _search() {
    final j = tables;
    if (j == null) return;
    final q = _q.text.trim();
    setState(() =>
        _suggestions = q.isEmpty ? const [] : j.set.suggest(q));
  }

  void _take(String v) {
    setState(() {
      _verb = v;
      _q.text = v;
      _q.selection = TextSelection.collapsed(offset: v.length);
      _suggestions = const [];
      _clitic = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.translator;
    if (tables == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final j = tables!;
    /* the header ( language name, search bar, suggestions ) stays
       fixed at the top of the screen for every language; only the table
       of the verb scrolls. */
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /* the name of the conjugated language, always visible in the screen */
          Text(t('conj-${widget.language}'),
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          /* bar: field, definition, pronominal (fr) */
          Row(
            children: [
              Expanded(
                child: Focus(
                  onKeyEvent: (node, e) {
                    if (e is KeyDownEvent &&
                        e.logicalKey == LogicalKeyboardKey.tab &&
                        _suggestions.isNotEmpty) {
                      final i = _suggestions.indexOf(_q.text.trim());
                      var k = i < 0 ? 0 : (HardwareKeyboard.instance.isShiftPressed ? i - 1 : i + 1);
                      k = k < 0 ? _suggestions.length - 1 : k % _suggestions.length;
                      final word = _suggestions[k];
                      _q.text = word;
                      _q.selection =
                          TextSelection.collapsed(offset: word.length);
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                  controller: _q,
                  decoration: InputDecoration(
                    hintText: t('chercher-verbe'),
                    isDense: true,
                    suffixIcon: IconButton(
                      tooltip: t('aleatoire'),
                      icon: const Icon(Icons.casino),
                      onPressed: () => _take(j.set.randomVerb()),
                    ),
                  ),
                  onSubmitted: (v) {
                    final s = j.set.suggest(v.trim());
                    if (s.isNotEmpty) _take(s.first);
                  },
                ),
                ),
              ),
              if (widget.language == 'fr')
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Row(
                    children: [
                      Switch(
                        value: _clitic && j.knows(_withoutSe(_verb)),
                        onChanged: (b) => setState(() => _clitic = b),
                      ),
                      Text(t('forme-pronominale'),
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
            ],
          ),
          if (_suggestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final v in _suggestions.take(24))
                    ActionChip(label: Text(v), onPressed: () => _take(v)),
                ],
              ),
            ),
          const SizedBox(height: 8),
          if (!_verb.isEmpty && !j.knows(_withoutSe(_verb)))
            Text(t('aucun-verbe'),
                style:
                    const TextStyle(fontStyle: FontStyle.italic, fontSize: 13)),
          if (_verb.isNotEmpty && j.knows(_withoutSe(_verb)))
            Expanded(
              child: SingleChildScrollView(
                child: _VerbCard(j, _withoutSe(_verb), _clitic, t,
                    widget.language,
                    onPick: _take),
              ),
            ),
        ],
      ),
    );
  }
}

String _withoutSe(String v) => v.startsWith('se ') ? v.substring(3) : v;

/* The first letter in uppercase, the rest unchanged */
String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/* ---------------- the card of a verb ---------------- */

class _VerbCard extends StatefulWidget {
  final ConjugTables j;
  final String v;
  final bool clitic;
  final Translator t;
  final String language;
  final void Function(String)? onPick;
  const _VerbCard(this.j, this.v, this.clitic, this.t, this.language,
      {this.onPick});

  @override
  State<_VerbCard> createState() => _VerbCardState();
}

class _VerbCardState extends State<_VerbCard> {
  ConjugTables get j => widget.j;
  String get v => widget.v;
  bool get clitic => widget.clitic;
  Translator get t => widget.t;
  String get language => widget.language;
  void Function(String)? get onPick => widget.onPick;

  /* setting: show only the definitions of the Wiktionary */
  bool _wiktOnly = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) {
        setState(() => _wiktOnly = p.getBool('defs-wikt-seules') ?? false);
      }
    });
  }

  /* The age of a source: the oldest wins the duplicates. The public
     domain dictionaries first by year, then the glossaries of the
     project, finally the Wiktionaries. */
  static const _ages = <String, int>{
    'Littré (1872-1877)': 1,
    'Sanders 1876': 2,
    'Petrocchi 1887': 3,
    'Słownik warszawski 1900': 4,
    'Webster 1913': 5,
    'Figueiredo 1913': 5,
    'Real Academia 1913-1914': 5,
    'Académie 8e (1932-1935)': 6,
    'projet': 7,
    'Glossaire du générateur du projet': 7,
  };

  static bool _isWikt(String label) =>
      label.contains('Wiktionary') || label.contains('Wiktionnaire');

  static int _sourceAge(String label) =>
      _ages[label] ?? 8; // Wiktionaries and unknown: the most recent

  /* The duplicate key: same text up to the final point and the apostrophes. */
  static String _meaningKey(String text) {
    var c = text.toLowerCase().trim();
    c = c.replaceAll('\u2019', "").replaceAll('\u2018', "");
    c = c.replaceAll(RegExp(r'\s+'), ' ');
    while (c.endsWith('.')) {
      c = c.substring(0, c.length - 1);
    }
    return c.trim();
  }

  /* The shown meanings: everything, or the Wiktionary alone per the
     setting; on a duplicate the oldest source is kept, each meaning
     stays at the place of its group. */
  List<Meaning> _shownMeanings(List<Meaning> defs) {
    if (defs.isEmpty) return defs;
    final base = _wiktOnly
        ? defs.where((d) => _isWikt(d.label)).toList()
        : defs;
    if (base.isEmpty) return base;
    final keys = [for (final d in base) _meaningKey(d.text)];
    final kept = <bool>[];
    for (var i = 0; i < base.length; i++) {
      var keep = true;
      for (var k = 0; k < base.length; k++) {
        if (k != i && keys[k] == keys[i]) {
          final ai = _sourceAge(base[i].label);
          final ak = _sourceAge(base[k].label);
          if (ak < ai || (ak == ai && k < i)) {
            keep = false;
            break;
          }
        }
      }
      kept.add(keep);
    }
    return [
      for (var i = 0; i < base.length; i++)
        if (kept[i]) base[i]
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cap = j.header(v, clitic: clitic);
    final defs = _shownMeanings(j.definition(v));
    final body = <Widget>[
      Text(cap['titre'] ?? v,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
      const SizedBox(height: 2),
      if (cap.containsKey('auxiliaire'))
        Text(
            '${t('dé-aux')} : ${cap['auxiliaire']}'
            '${cap.containsKey('groupe') ? ' • ${t('dé-groupe')} ${cap['groupe']}' : ''}',
            style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor)),
      Text(
          j.verbSource(v) == 'w' ? t('src-wikt') : t('src-gene'),
          style: TextStyle(
              fontSize: 12,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(.55))),
      const SizedBox(height: 8),
    ];
    if (language == 'en') {
      body.add(_englishGridWidget());
      body.add(const SizedBox(height: 8));
    } else {
      body.add(_table());
      body.add(const SizedBox(height: 12));
    }
    /* the definition frame: the source appears above each group; the
       definitions form their own selection area */
    if (defs.isNotEmpty) {
      body.add(SelectionArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(11, 7, 11, 9),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._meaningGroups(defs),
            ],
          ),
        ),
      ));
    } else {
      body.add(Text(t('indisponible'),
          style: const TextStyle(
              fontStyle: FontStyle.italic, fontSize: 13, color: Colors.grey)));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: body,
    );
  }

  Widget _numbered(int n, Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 20,
            child: Text('$n.',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          Expanded(child: child),
        ]),
      );

  /* The meanings grouped by consecutive label: the label ( often the
     source, e.g. Engl. Wiktionary ) appears only once per group,
     instead of repeating on every line. The numbering continues. */
  List<Widget> _meaningGroups(List<Meaning> defs) {
    if (defs.length < 2) return [_meaning(defs.first, small: false)];
    final out = <Widget>[];
    var number = 0;
    var start = 0;
    void group(int end) {
      final label = defs[start].label;
      if (label.isNotEmpty) {
        out.add(Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 1),
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ));
      }
      for (var k = start; k < end; k++) {
        number++;
        out.add(_numbered(number, _meaningText(defs[k])));
      }
    }

    for (var i = 1; i <= defs.length; i++) {
      if (i == defs.length || defs[i].label != defs[start].label) {
        group(i);
        start = i;
      }
    }
    return out;
  }

  /* a meaning without its label, for the already titled groups */
  Widget _meaningText(Meaning d) {
    return Text(_capitalize(d.text),
        style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic));
  }

  Widget _meaning(Meaning d, {bool small = true}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (d.label.isNotEmpty)
        Text(d.label,
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: small ? FontWeight.w400 : FontWeight.w400)),
      Text(_capitalize(d.text),
          style: TextStyle(
              fontSize: small ? 12 : 14, fontStyle: FontStyle.italic)),
    ]);
  }

  /* the table of tenses: one common template for every language.
     Each mood is a block with its title; its tenses are coloured
     cards laid side by side ( they wrap when the width is missing ),
     one person per line in each card. */
  Widget _table() {
    final moods = j.render(v, clitic: clitic);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final m in moods) ...[
          _moodHeader(m.name),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              /* each tense is its own selection area: the forms of one
                 tense are copied, never across several tenses */
              for (final tp in m.tenses)
                SelectionArea(child: _tenseCard(tp)),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  /* the title of a mood, underlined with the accent colour */
  Widget _moodHeader(String name) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 3),
      decoration: BoxDecoration(
          color: accent.withOpacity(.12),
          borderRadius: BorderRadius.circular(6)),
      child: Text(_capitalize(name),
          style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 13, color: accent)),
    );
  }

  /* a tense card: natural width, to lay several tenses horizontally;
     the ending stays highlighted in bold burgundy */
  Widget _tenseCard(Tense tp) {
    final tint = _tints[conjTenseTint(tp.name)];
    final discreet = Theme.of(context).hintColor;
    final absent = Theme.of(context).disabledColor;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 8, 7),
      decoration:
          BoxDecoration(color: tint, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_capitalize(tp.name),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 2),
          for (var i = 0; i < tp.val.length; i++)
            if (tp.val[i].isNotEmpty || tp.pers[i].isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 0.5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 88,
                      child: Text(tp.pers[i],
                          style: TextStyle(fontSize: 12, color: discreet)),
                    ),
                    Flexible(
                        child: tp.val[i].isEmpty
                            ? Text('—',
                                style: TextStyle(fontSize: 12, color: absent))
                            : _form(
                                tp.val[i],
                                tp.end == null
                                    ? ''
                                    : (i < tp.end!.length ? tp.end![i] : ''))),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  /* a full form; the ending carried by fin goes bold in the colour of
     the template ( burgundy in light, pink in dark ), the segments
     between parentheses switch to grey */
  Widget _form(String val, String fin) {
    final pieces = conjFormPieces(val, fin);
    final endStyle = conjEndingStyle(context);
    final greyStyle = conjParenStyle(context);
    return Text.rich(
      TextSpan(
        children: [
          for (final p in pieces) ...[
            ...conjGreySpans(p.plain, greyStyle),
            if (p.end != null)
              TextSpan(text: p.end, style: endStyle),
          ],
        ],
      ),
      style: const TextStyle(fontSize: 14),
    );
  }

  /* the English grid: seven clickable neighbours */
  Widget _englishGridWidget() {
    final g = j.englishGrid(v);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final l in g)
          InkWell(
            onTap: l['verbe'] == v ? null : () => onPick?.call(l['verbe']!),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: l['verbe'] == v
                    ? Theme.of(context).colorScheme.primary.withOpacity(.25)
                    : Theme.of(context).colorScheme.onSurface.withOpacity(.05),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l['verbe']!,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: l['verbe'] == v
                                ? Theme.of(context).colorScheme.primary
                                : null)),
                    /* the (US) and (GB) markers switch to grey */
                    Text.rich(
                        TextSpan(children: [
                          ...conjGreySpans('${l['preterit']!} / ${l['pp']!}',
                              conjParenStyle(context)),
                        ]),
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).hintColor)),
                  ]),
            ),
          ),
      ],
    );
  }
}
