/* L ecran de conjugaison : recherche, de, forme pronominale, planche de
   temps teinte, definition avec sa ligne de source, grille anglaise.
   Portage de l interface des modules web de conjugaison.
   SPDX-License-Identifier : MIT. */
import 'package:flutter/material.dart';

import '../bdd.dart' as bdd;
import '../l10n.dart';
import 'moteurs.dart';
import 'socle.dart';

/* Les dix fonds translucides de la planche, web/css/styles.css .conj-tK */
const _teintes = <Color>[
  Color(0x298ab4ff), // 0 present, bleu
  Color(0x296fd8c9), // 1 imparfait, teal
  Color(0x2bffce7a), // 2 passe simple, ambre
  Color(0x26b89aff), // 3 futur, violet
  Color(0x268fd88f), // 4 compose, vert
  Color(0x26ff9ab6), // 5 plus-que-parfait, rose
  Color(0x29ffb37a), // 6 passe anterieur, orange
  Color(0x24d68aff), // 7 futur anterieur, mauve
  Color(0x2bd8c9a0), // 8 passe, sable
  Color(0x267ad4ff), // 9 autre temps, cyan
];

/* Les lignes de source des definitions, une par langue */
const _sources = <String, String>{
  'fr': "Littré (1872-1877) et Dictionnaire de l'Académie française, "
      '8e édition (1932-1935), domaine public, complété du Wiktionary '
      '(CC BY-SA 4.0)',
  'en': "Webster's Revised Unabridged Dictionary, édition 1913 (GCIDE), "
      'domaine public, complété du Wiktionary (CC BY-SA 4.0)',
  'es': 'Diccionario de la lengua castellana, Real Academia Española, '
      '14e édition, 1913, domaine public, complété du Wiktionary '
      '(CC BY-SA 4.0)',
  'it': 'Glossaire du projet et Wiktionary via kaikki.org (CC BY-SA 4.0)',
  'pt': 'Glossaire du projet et Wiktionary via kaikki.org (CC BY-SA 4.0)',
  'de': 'Glossaire du projet et Wiktionary via kaikki.org (CC BY-SA 4.0)',
  'pl': 'Définitions du Wiktionary polonais (dumps pl.wiktionary) pour '
      '4 378 verbes, glossaires anglais du Wiktionary via kaikki.org pour '
      'les autres (CC BY-SA 4.0)',
  'cs': 'Définitions du Wiktionary tchèque (dumps cs.wiktionary) pour '
      '1 931 verbes, glossaires anglais du Wiktionary via tous les '
      'wiktionary pour les autres (CC BY-SA 4.0)',
  'ro': 'Définitions du Wiktionary roumain (dumps ro.wiktionary) pour '
      '5 437 verbes, glossaires anglais du Wiktionary via tous les '
      'wiktionary pour les autres (CC BY-SA 4.0)',
};

class EcranConjugaison extends StatefulWidget {
  final String langue; // fr, en, es, de, it, pt
  final Traducteur trad;
  EcranConjugaison(this.langue, this.trad, {super.key});

  @override
  State<EcranConjugaison> createState() => _EcranConjugaisonState();
}

class _EcranConjugaisonState extends State<EcranConjugaison> {
  PlanchesConjug? jeu;
  final _q = TextEditingController();
  List<String> _sug = const [];
  String _verbe = '';
  bool _clit = false;

  @override
  void initState() {
    super.initState();
    _q.addListener(_chercher);
    bdd.tranchesConj(widget.langue).then((j) {
      if (!mounted) return;
      setState(() {
        jeu = j;
        _verbe = j.jeu.hasard();
      });
    });
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  void _chercher() {
    final j = jeu;
    if (j == null) return;
    final q = _q.text.trim();
    setState(() => _sug = q.isEmpty ? const [] : j.jeu.suggestions(q));
  }

  void _prendre(String v) {
    setState(() {
      _verbe = v;
      _q.text = v;
      _q.selection = TextSelection.collapsed(offset: v.length);
      _sug = const [];
      _clit = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.trad;
    if (jeu == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final j = jeu!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /* le nom de la langue conjuguee, toujours visible dans l'ecran */
          Text(t('conj-${widget.langue}'),
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          /* barre : champ, de, pronominal (fr) */
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _q,
                  decoration: InputDecoration(
                    hintText: t('chercher-verbe'),
                    isDense: true,
                    suffixIcon: IconButton(
                      tooltip: t('aleatoire'),
                      icon: const Icon(Icons.casino),
                      onPressed: () => _prendre(j.jeu.hasard()),
                    ),
                  ),
                  onSubmitted: (v) {
                    final s = j.jeu.suggestions(v.trim());
                    if (s.isNotEmpty) _prendre(s.first);
                  },
                ),
              ),
              if (widget.langue == 'fr')
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Row(
                    children: [
                      Switch(
                        value: _clit && j.connait(_sansSe(_verbe)),
                        onChanged: (b) => setState(() => _clit = b),
                      ),
                      Text(t('forme-pronominale'),
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
            ],
          ),
          if (_sug.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final v in _sug.take(24))
                    ActionChip(label: Text(v), onPressed: () => _prendre(v)),
                ],
              ),
            ),
          const SizedBox(height: 8),
          if (!_verbe.isEmpty && !j.connait(_sansSe(_verbe)))
            Text(t('aucun-verbe'),
                style:
                    const TextStyle(fontStyle: FontStyle.italic, fontSize: 13)),
          if (_verbe.isNotEmpty && j.connait(_sansSe(_verbe))) ...[
            _CarteVerbe(j, _sansSe(_verbe), _clit, _sources[widget.langue]!, t,
                widget.langue,
                onChoisir: _prendre),
          ],
        ],
      ),
    );
  }
}

String _sansSe(String v) => v.startsWith('se ') ? v.substring(3) : v;

/* ---------------- la carte d un verbe ---------------- */

class _CarteVerbe extends StatefulWidget {
  final PlanchesConjug j;
  final String v;
  final bool clit;
  final String source;
  final Traducteur t;
  final String langue;
  final void Function(String)? onChoisir;
  const _CarteVerbe(this.j, this.v, this.clit, this.source, this.t, this.langue,
      {this.onChoisir});

  @override
  State<_CarteVerbe> createState() => _CarteVerbeEtat();
}

class _CarteVerbeEtat extends State<_CarteVerbe> {
  PlanchesConjug get j => widget.j;
  String get v => widget.v;
  bool get clit => widget.clit;
  String get source => widget.source;
  Traducteur get t => widget.t;
  String get langue => widget.langue;
  void Function(String)? get onChoisir => widget.onChoisir;

  @override
  Widget build(BuildContext context) {
    final cap = j.chapeau(v, clit: clit);
    final defs = j.definition(v);
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
          j.sourceVerbe(v) == 'w' ? t('src-wikt') : t('src-gene'),
          style: TextStyle(
              fontSize: 12,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(.55))),
      const SizedBox(height: 8),
    ];
    if (langue == 'en') {
      body.add(_grilleEn());
      body.add(const SizedBox(height: 8));
    } else {
      body.add(_planche());
      body.add(const SizedBox(height: 12));
    }
    /* l encadre definition + source */
    if (defs.isNotEmpty) {
      body.add(Container(
        padding: const EdgeInsets.fromLTRB(11, 7, 11, 9),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (defs.length < 2)
              _sens(defs.first, petit: false)
            else ...[
              for (var i = 0; i < defs.length; i++)
                _numere(i + 1, _sens(defs[i], petit: false)),
            ],
            const SizedBox(height: 2),
            Text(source,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(.55))),
          ],
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

  Widget _numere(int n, Widget enfant) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 20,
            child: Text('$n.',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          Expanded(child: enfant),
        ]),
      );

  Widget _sens(Sens d, {bool petit = true}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (d.etiquette.isNotEmpty)
        Text(d.etiquette,
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: petit ? FontWeight.w400 : FontWeight.w400)),
      Text(d.texte,
          style: TextStyle(
              fontSize: petit ? 12 : 14, fontStyle: FontStyle.italic)),
    ]);
  }

  /* la planche des temps, cartes flottantes colorees */
  Widget _planche() {
    final modes = j.rend(v, clit: clit);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        for (final m in modes)
          for (final tp in m.temps) _carteTemps(m.nom, tp),
      ],
    );
  }

  Widget _carteTemps(String mode, Temps tp) {
    final teinte = _teintes[conjTeinteTemps(tp.nom)];
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      decoration:
          BoxDecoration(color: teinte, borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$mode : ${tp.nom}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 3),
        for (var i = 0; i < tp.val.length; i++)
          if (tp.val[i].isNotEmpty || tp.pers[i].isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Row(children: [
                SizedBox(
                  width: 110,
                  child: Text(tp.pers[i],
                      style: TextStyle(
                          fontSize: 13, color: Theme.of(context).hintColor)),
                ),
                Expanded(
                    child: tp.val[i].isEmpty
                        ? Text('—',
                            style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).disabledColor))
                        : _forme(
                            tp.val[i],
                            tp.fin == null
                                ? ''
                                : (i < tp.fin!.length ? tp.fin![i] : ''))),
              ]),
            ),
      ]),
    );
  }

  /* une forme pleine ; la terminaison portee par fin passe en rouge bordeaux gras */
  Widget _forme(String val, String fin) {
    final pieces = conjTerme(val, fin);
    return Text.rich(
      TextSpan(
        children: [
          for (final p in pieces) ...[
            if (p.noir.isNotEmpty) TextSpan(text: p.noir),
            if (p.fin != null)
              TextSpan(
                  text: p.fin,
                  style: const TextStyle(
                      color: Color(0xff7d1f2e), fontWeight: FontWeight.w700)),
          ],
        ],
      ),
      style: const TextStyle(fontSize: 14),
    );
  }

  /* la grille anglaise : sept voisines cliquables */
  Widget _grilleEn() {
    final g = j.grilleEn(v);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final l in g)
          InkWell(
            onTap: l['verbe'] == v ? null : () => onChoisir?.call(l['verbe']!),
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
                    Text('${l['preterit']!} / ${l['pp']!}',
                        style: TextStyle(
                            fontSize: 12, color: Theme.of(context).hintColor)),
                  ]),
            ),
          ),
      ],
    );
  }
}
