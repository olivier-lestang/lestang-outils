/* Password: uniform cryptographic drawing, 100 % local.
   Port of the web card ( js/outils/mot-de-passe.js ): four types,
   length 4 to 64, character sets of choice, ambiguous ones excluded
   at will. SPDX-License-Identifier: MIT. */
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n.dart';

const _sets = <String, String>{
  'upper': 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
  'lower': 'abcdefghijklmnopqrstuvwxyz',
  'digits': '0123456789',
  'digits-complet': '0123456789',
  'symbols': r'!@#$%^&*()-_=+[]{}<>?,.;:',
};
const _hex = '0123456789abcdef';
const _b64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
final _ambiguous = RegExp(r'[0O1lI|]');

final _rng = Random.secure();

String _draw(String set, int n) =>
    List.generate(n, (_) => set[_rng.nextInt(set.length)]).join();

class PasswordScreen extends StatefulWidget {
  final Translator trad;
  const PasswordScreen(this.trad, {super.key});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  String _type = 'password';
  int _length = 16;
  final _opts = {'upper': true, 'lower': true, 'digits': true, 'symbols': true};
  bool _noAmbiguous = false;
  String _output = '';

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    String out;
    if (_type == 'password') {
      var set = '';
      for (final e in _opts.entries) {
        if (e.value) set += _sets[e.key] ?? '';
      }
      if (_noAmbiguous) set = set.replaceAll(_ambiguous, '');
      if (set.isEmpty) set = _sets['lower']!;
      out = _draw(set, _length);
    } else if (_type == 'pin') {
      out = _draw(_sets['digits-complet']!, _length.clamp(4, 12));
    } else if (_type == 'hex') {
      out = _draw(_hex, _length);
    } else {
      out = _draw(_b64, _length);
    }
    setState(() => _output = out);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.trad;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SelectableText(_output.isEmpty ? '—' : _output,
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
                _generate();
              }
            },
          ),
          SizedBox(
            width: 260,
            child: Row(children: [
              const Text('4'),
              Expanded(
                child: Slider(
                  value: _length.toDouble(),
                  min: 4,
                  max: 64,
                  divisions: 60,
                  label: '$_length',
                  onChanged: (v) {
                    _length = v.round();
                    _generate();
                  },
                ),
              ),
              const Text('64'),
              SizedBox(
                  width: 32,
                  child: Text('$_length',
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
                  _generate();
                },
              ),
            FilterChip(
              label: const Text('0 O 1 l I |'),
              selected: _noAmbiguous,
              onSelected: (b) {
                _noAmbiguous = b;
                _generate();
              },
            ),
          ],
        ),
      const SizedBox(height: 12),
      Wrap(spacing: 8, children: [
        FilledButton.icon(
          onPressed: _generate,
          icon: const Icon(Icons.refresh),
          label:
              Text(t('aleatoire').contains('hasard') ? 'Générer' : 'Generate'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: _output));
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