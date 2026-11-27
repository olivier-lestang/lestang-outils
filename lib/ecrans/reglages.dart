/* Réglages : langue, thème, ordre des cartes, sauvegarde des préférences.
   Les choix vivent dans shared_preferences. SPDX-License-Identifier : MIT. */
import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n.dart';
import '../sauvegarde.dart';

enum ModeTheme { systeme, clair, sombre }

Future<String> lireLangue() async {
  final p = await SharedPreferences.getInstance();
  return p.getString('langue') ?? langueSysteme();
}

Future<ModeTheme> lireTheme() async {
  final p = await SharedPreferences.getInstance();
  final v = p.getString('theme') ?? 'systeme';
  return v == 'clair'
      ? ModeTheme.clair
      : v == 'sombre'
          ? ModeTheme.sombre
          : ModeTheme.systeme;
}

class EcranReglages extends StatefulWidget {
  final String langue;
  final ModeTheme theme;
  final List<String> ordre;
  final void Function(String langue) surLangue;
  final void Function(ModeTheme theme) surTheme;
  final void Function(List<String> ordre) surOrdre;
  const EcranReglages(this.langue, this.theme, this.ordre, this.surLangue,
      this.surTheme, this.surOrdre,
      {super.key});

  @override
  State<EcranReglages> createState() => _EcranReglagesState();
}

class _EcranReglagesState extends State<EcranReglages> {
  String? _message;
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

  void _basculerWikt(bool v) {
    setState(() => _wiktSeules = v);
    SharedPreferences.getInstance().then((p) => p.setBool('defs-wikt-seules', v));
  }

  /* export : toutes les preferences dans un fichier JSON */
  Future<void> _exporter() async {
    final p = await SharedPreferences.getInstance();
    final sortie = <String, Object>{};
    for (final cle in p.getKeys()) {
      final v = p.get(cle);
      if (v == null) continue;
      if (v is List<String>) {
        sortie[cle] = v;
      } else {
        sortie[cle] = v;
      }
    }
    try {
      final ok = await enregistrerTexte('lestang-outils-preferences.json',
          const JsonEncoder.withIndent('  ').convert(sortie));
      if (ok) setState(() => _message = 'OK');
    } catch (e) {
      setState(() => _message = '$e');
    }
  }

  /* import : fusionne un fichier JSON de preferences */
  Future<void> _importer() async {
    final fichier = await openFile(acceptedTypeGroups: const [
      XTypeGroup(label: 'JSON', extensions: ['json'])
    ]);
    if (fichier == null) return;
    try {
      final texte = await File(fichier.path).readAsString();
      final d = jsonDecode(texte);
      if (d is! Map) throw const FormatException('json');
      final p = await SharedPreferences.getInstance();
      for (final e in d.entries) {
        final cle = e.key as String;
        final v = e.value;
        if (v is String) {
          await p.setString(cle, v);
        } else if (v is List) {
          await p.setStringList(cle, v.map((x) => '$x').toList());
        } else if (v is int) {
          await p.setInt(cle, v);
        } else if (v is double) {
          await p.setDouble(cle, v);
        } else if (v is bool) {
          await p.setBool(cle, v);
        }
      }
      setState(() => _message = 'OK');
    } catch (e) {
      setState(() => _message = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Traducteur(widget.langue);
    return ListView(children: [
      Text(t('langue'), style: const TextStyle(fontWeight: FontWeight.w600)),
      Wrap(spacing: 8, children: [
        for (final l in languesUi)
          ChoiceChip(
            label: Text({
              'fr': 'Français',
              'en': 'English',
              'es': 'Español',
              'pt': 'Português',
              'it': 'Italiano',
              'de': 'Deutsch',
            }[l]!),
            selected: l == widget.langue,
            onSelected: (_) => widget.surLangue(l),
          ),
      ]),
      const SizedBox(height: 16),
      Text(t('theme'), style: const TextStyle(fontWeight: FontWeight.w600)),
      Wrap(spacing: 8, children: [
        ChoiceChip(
            label: Text(t('theme-systeme')),
            selected: widget.theme == ModeTheme.systeme,
            onSelected: (_) => widget.surTheme(ModeTheme.systeme)),
        ChoiceChip(
            label: Text(t('theme-clair')),
            selected: widget.theme == ModeTheme.clair,
            onSelected: (_) => widget.surTheme(ModeTheme.clair)),
        ChoiceChip(
            label: Text(t('theme-sombre')),
            selected: widget.theme == ModeTheme.sombre,
            onSelected: (_) => widget.surTheme(ModeTheme.sombre)),
      ]),
      const SizedBox(height: 16),
      Text(t('defs-wikt'),
          style: const TextStyle(fontWeight: FontWeight.w600)),
      SwitchListTile(
        dense: true,
        value: _wiktSeules,
        onChanged: _basculerWikt,
        title: Text(t('defs-wikt-titre')),
        subtitle: Text(t('defs-wikt-aide'), style: const TextStyle(fontSize: 12)),
      ),
      const SizedBox(height: 16),
      Text(t('ordre-cartes'),
          style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 320),
        child: ReorderableListView.builder(
          itemCount: widget.ordre.length,
          onReorder: (ancien, nouveau) {
            final liste = [...widget.ordre];
            if (nouveau > ancien) nouveau--;
            final e = liste.removeAt(ancien);
            liste.insert(nouveau, e);
            widget.surOrdre(liste);
          },
          itemBuilder: (context, i) => ListTile(
            key: ValueKey(widget.ordre[i]),
            dense: true,
            leading: const Icon(Icons.drag_handle),
            title: Text(t(widget.ordre[i])),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Text(t('sauvegarde'),
          style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Wrap(spacing: 10, children: [
        OutlinedButton.icon(
            onPressed: _exporter,
            icon: const Icon(Icons.file_upload),
            label: Text(t('sauvegarde-exporter'))),
        OutlinedButton.icon(
            onPressed: _importer,
            icon: const Icon(Icons.file_download),
            label: Text(t('sauvegarde-importer'))),
      ]),
      if (_message != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(_message!, style: const TextStyle(fontSize: 13)),
        ),
    ]);
  }
}
