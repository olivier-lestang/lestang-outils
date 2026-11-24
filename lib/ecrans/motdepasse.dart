/* Mot de passe : tirage cryptographique uniforme, 100 % local.
   Portage de la carte du web ( js/outils/mot-de-passe.js ) : quatre types,
   longueur 4 a 64, jeux de caracteres au choix, ambigus exclus au choix.
   SPDX-License-Identifier : MIT. */
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n.dart';

const _jeux = <String, String>{
  'upper': 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
  'lower': 'abcdefghijklmnopqrstuvwxyz',
  'digits': '0123456789',
  'digits-complet': '0123456789',
  'symbols': r'!@#$%^&*()-_=+[]{}<>?,.;:',
};
const _hex = '0123456789abcdef';
const _b64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
final _ambigu = RegExp(r'[0O1lI|]');

final _rng = Random.secure();

String _tirer(String jeu, int n) =>
    List.generate(n, (_) => jeu[_rng.nextInt(jeu.length)]).join();

class EcranMotDePasse extends StatefulWidget {
  final Traducteur trad;
  const EcranMotDePasse(this.trad, {super.key});

  @override
  State<EcranMotDePasse> createState() => _EcranMotDePasseState();
}

class _EcranMotDePasseState extends State<EcranMotDePasse> {
  String _type = 'password';
  int _longueur = 16;
  final _opts = {'upper': true, 'lower': true, 'digits': true, 'symbols': true};
  bool _sansAmbigus = false;
  String _sortie = '';

  @override
  void initState() {
    super.initState();
    _generer();
  }

  void _generer() {
    String out;
    if (_type == 'password') {
      var jeu = '';
      for (final e in _opts.entries) {
        if (e.value) jeu += _jeux[e.key] ?? '';
      }
      if (_sansAmbigus) jeu = jeu.replaceAll(_ambigu, '');
      if (jeu.isEmpty) jeu = _jeux['lower']!;
      out = _tirer(jeu, _longueur);
    } else if (_type == 'pin') {
      out = _tirer(_jeux['digits-complet']!, _longueur.clamp(4, 12));
    } else if (_type == 'hex') {
      out = _tirer(_hex, _longueur);
    } else {
      out = _tirer(_b64, _longueur);
    }
    setState(() => _sortie = out);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.trad;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SelectableText(_sortie.isEmpty ? '—' : _sortie,
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 1)),
      const SizedBox(height: 10),
      Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          DropdownButton<String>(
            value: _type,
            items: const [
              DropdownMenuItem(
                  value: 'password', child: Text('Mot de passe classique')),
              DropdownMenuItem(value: 'pin', child: Text('Code PIN')),
              DropdownMenuItem(value: 'hex', child: Text('Clé hexadécimale')),
              DropdownMenuItem(value: 'base64', child: Text('Clé Base64')),
            ],
            onChanged: (v) {
              if (v != null) {
                _type = v;
                _generer();
              }
            },
          ),
          SizedBox(
            width: 260,
            child: Row(children: [
              const Text('4'),
              Expanded(
                child: Slider(
                  value: _longueur.toDouble(),
                  min: 4,
                  max: 64,
                  divisions: 60,
                  label: '$_longueur',
                  onChanged: (v) {
                    _longueur = v.round();
                    _generer();
                  },
                ),
              ),
              const Text('64'),
              SizedBox(
                  width: 32,
                  child: Text('$_longueur',
                      textAlign: TextAlign.right, style: const TextStyle())),
            ]),
          ),
        ],
      ),
      if (_type == 'password')
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            for (final e in _opts.entries)
              FilterChip(
                label: Text(e.key == 'upper'
                    ? 'A-Z'
                    : e.key == 'lower'
                        ? 'a-z'
                        : e.key == 'digits'
                            ? '0-9'
                            : '!@#…'),
                selected: e.value,
                onSelected: (b) {
                  _opts[e.key] = b;
                  _generer();
                },
              ),
            FilterChip(
              label: const Text('0 O 1 l I |'),
              selected: _sansAmbigus,
              onSelected: (b) {
                _sansAmbigus = b;
                _generer();
              },
            ),
          ],
        ),
      const SizedBox(height: 12),
      Wrap(spacing: 8, children: [
        FilledButton.icon(
          onPressed: _generer,
          icon: const Icon(Icons.refresh),
          label:
              Text(t('aleatoire').contains('hasard') ? 'Générer' : 'Generate'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: _sortie));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(t('copie-ok')),
                duration: const Duration(seconds: 1)));
          },
          icon: const Icon(Icons.copy),
          label: Text(t('copier')),
        ),
      ]),
    ]);
  }
}
