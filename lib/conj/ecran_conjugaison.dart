/* L ecran de conjugaison : recherche, de, forme pronominale, planche de
   temps teinte, definition avec la source au-dessus de chaque groupe, grille anglaise.
   Portage de l interface des modules web de conjugaison.
   SPDX-License-Identifier : MIT. */
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
            _CarteVerbe(j, _sansSe(_verbe), _clit, t, widget.langue,
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
  final Traducteur t;
  final String langue;
  final void Function(String)? onChoisir;
  const _CarteVerbe(this.j, this.v, this.clit, this.t, this.langue,
      {this.onChoisir});

  @override
  State<_CarteVerbe> createState() => _CarteVerbeEtat();
}

class _CarteVerbeEtat extends State<_CarteVerbe> {
  PlanchesConjug get j => widget.j;
  String get v => widget.v;
  bool get clit => widget.clit;
  Traducteur get t => widget.t;
  String get langue => widget.langue;
  void Function(String)? get onChoisir => widget.onChoisir;

  /* reglage : ne montrer que les definitions du Wiktionary */
  bool _wiktSeules = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) {
        setState(() => _wiktSeules = p.getBool('defs-wikt-seules') ?? false);
      }
    });
  }

  /* L age d une source : la plus ancienne gagne les doublons. Les
     dictionnaires du domaine public d abord par annee, puis les
     glossaires du projet, enfin les Wiktionary. */
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

  static bool _estWikt(String etiquette) =>
      etiquette.contains('Wiktionary') || etiquette.contains('Wiktionnaire');

  static int _ageSource(String etiquette) =>
      _ages[etiquette] ?? 8; // Wiktionary et inconnues : les plus recentes

  /* La cle de doublon : meme texte au point final et aux apostrophes pres. */
  static String _cleSens(String texte) {
    var c = texte.toLowerCase().trim();
    c = c.replaceAll('\u2019', "'").replaceAll('\u2018', "'");
    c = c.replaceAll(RegExp(r'\s+'), ' ');
    while (c.endsWith('.')) {
      c = c.substring(0, c.length - 1);
    }
    return c.trim();
  }

  /* Les sens affiches : tout, ou le Wiktionary seul selon le reglage ;
     en cas de doublon la source la plus ancienne est gardee, chaque
     sens reste a la place de son groupe. */
  List<Sens> _sensAffiches(List<Sens> defs) {
    if (defs.isEmpty) return defs;
    final base = _wiktSeules
        ? defs.where((d) => _estWikt(d.etiquette)).toList()
        : defs;
    if (base.isEmpty) return base;
    final cles = [for (final d in base) _cleSens(d.texte)];
    final gardes = <bool>[];
    for (var i = 0; i < base.length; i++) {
      var garder = true;
      for (var k = 0; k < base.length; k++) {
        if (k != i && cles[k] == cles[i]) {
          final ai = _ageSource(base[i].etiquette);
          final ak = _ageSource(base[k].etiquette);
          if (ak < ai || (ak == ai && k < i)) {
            garder = false;
            break;
          }
        }
      }
      gardes.add(garder);
    }
    return [
      for (var i = 0; i < base.length; i++)
        if (gardes[i]) base[i]
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cap = j.chapeau(v, clit: clit);
    final defs = _sensAffiches(j.definition(v));
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
    /* l encadre definition : la source figure au-dessus de chaque groupe */
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
            ..._groupesSens(defs),
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

  /* Les sens groupes par etiquette consecutive : l etiquette ( souvent
     la source, ex. angl. Wiktionary ) n apparait qu une fois par groupe,
     au lieu de se repeter a chaque ligne. La numerotation continue. */
  List<Widget> _groupesSens(List<Sens> defs) {
    if (defs.length < 2) return [_sens(defs.first, petit: false)];
    final out = <Widget>[];
    var numero = 0;
    var debut = 0;
    void groupe(int fin) {
      final et = defs[debut].etiquette;
      if (et.isNotEmpty) {
        out.add(Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 1),
          child: Text(et,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ));
      }
      for (var k = debut; k < fin; k++) {
        numero++;
        out.add(_numere(numero, _sensTexte(defs[k])));
      }
    }

    for (var i = 1; i <= defs.length; i++) {
      if (i == defs.length || defs[i].etiquette != defs[debut].etiquette) {
        groupe(i);
        debut = i;
      }
    }
    return out;
  }

  /* un sens sans son etiquette, pour les groupes deja titres */
  Widget _sensTexte(Sens d) {
    return Text(d.texte,
        style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic));
  }

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

  /* la planche des temps : un gabarit commun a toutes les langues.
     Chaque mode est un bloc avec son titre ; ses temps sont des cartes
     colorees posees cote a cote ( elles passent a la ligne quand la
     largeur manque ), une personne par ligne dans chaque carte. */
  Widget _planche() {
    final modes = j.rend(v, clit: clit);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final m in modes) ...[
          _enteteMode(m.nom),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              for (final tp in m.temps) _carteTemps(tp),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  /* le titre d un mode, souligne de la couleur d accent */
  Widget _enteteMode(String nom) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 3),
      decoration: BoxDecoration(
          color: accent.withOpacity(.12),
          borderRadius: BorderRadius.circular(6)),
      child: Text(nom,
          style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 13, color: accent)),
    );
  }

  /* une carte de temps : largeur naturelle, pour poser plusieurs temps
     horizontalement ; la terminaison reste surlignee en bordeaux gras */
  Widget _carteTemps(Temps tp) {
    final teinte = _teintes[conjTeinteTemps(tp.nom)];
    final discret = Theme.of(context).hintColor;
    final absent = Theme.of(context).disabledColor;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 8, 7),
      decoration:
          BoxDecoration(color: teinte, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tp.nom,
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
                          style: TextStyle(fontSize: 12, color: discret)),
                    ),
                    Flexible(
                        child: tp.val[i].isEmpty
                            ? Text('—',
                                style: TextStyle(fontSize: 12, color: absent))
                            : _forme(
                                tp.val[i],
                                tp.fin == null
                                    ? ''
                                    : (i < tp.fin!.length ? tp.fin![i] : ''))),
                  ],
                ),
              ),
        ],
      ),
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
