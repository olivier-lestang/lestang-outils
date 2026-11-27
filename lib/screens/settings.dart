/* Settings: language, theme, card order, preference backup.
   The choices live in shared_preferences. SPDX-License-Identifier: MIT. */
import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../backup.dart';
import '../l10n.dart';

enum AppThemeMode { system, light, dark }

Future<String> readLanguage() async {
  final p = await SharedPreferences.getInstance();
  return p.getString('langue') ?? systemLanguage();
}

Future<AppThemeMode> readTheme() async {
  final p = await SharedPreferences.getInstance();
  final v = p.getString('theme') ?? 'systeme';
  return v == 'clair'
      ? AppThemeMode.light
      : v == 'sombre'
          ? AppThemeMode.dark
          : AppThemeMode.system;
}

class SettingsScreen extends StatefulWidget {
  final String language;
  final AppThemeMode theme;
  final List<String> order;
  final void Function(String language) onLanguage;
  final void Function(AppThemeMode theme) onTheme;
  final void Function(List<String> order) onOrder;
  const SettingsScreen(this.language, this.theme, this.order, this.onLanguage,
      this.onTheme, this.onOrder,
      {super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _message;
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

  void _toggleWikt(bool v) {
    setState(() => _wiktOnly = v);
    SharedPreferences.getInstance().then((p) => p.setBool('defs-wikt-seules', v));
  }

  /* export: every preference into a JSON file */
  Future<void> _export() async {
    final p = await SharedPreferences.getInstance();
    final out = <String, Object>{};
    for (final key in p.getKeys()) {
      final v = p.get(key);
      if (v == null) continue;
      if (v is List<String>) {
        out[key] = v;
      } else {
        out[key] = v;
      }
    }
    try {
      final ok = await saveText('lestang-outils-preferences.json',
          const JsonEncoder.withIndent('  ').convert(out));
      if (ok) setState(() => _message = 'OK');
    } catch (e) {
      setState(() => _message = '$e');
    }
  }

  /* import: merges a JSON file of preferences */
  Future<void> _import() async {
    final file = await openFile(acceptedTypeGroups: const [
      XTypeGroup(label: 'JSON', extensions: ['json'])
    ]);
    if (file == null) return;
    try {
      final text = await File(file.path).readAsString();
      final d = jsonDecode(text);
      if (d is! Map) throw const FormatException('json');
      final p = await SharedPreferences.getInstance();
      for (final e in d.entries) {
        final key = e.key as String;
        final v = e.value;
        if (v is String) {
          await p.setString(key, v);
        } else if (v is List) {
          await p.setStringList(key, v.map((x) => '$x').toList());
        } else if (v is int) {
          await p.setInt(key, v);
        } else if (v is double) {
          await p.setDouble(key, v);
        } else if (v is bool) {
          await p.setBool(key, v);
        }
      }
      setState(() => _message = 'OK');
    } catch (e) {
      setState(() => _message = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Translator(widget.language);
    return ListView(children: [
      Text(t('langue'), style: const TextStyle(fontWeight: FontWeight.w600)),
      Wrap(spacing: 8, children: [
        for (final l in uiLanguages)
          ChoiceChip(
            label: Text({
              'fr': 'Français',
              'en': 'English',
              'es': 'Español',
              'pt': 'Português',
              'it': 'Italiano',
              'de': 'Deutsch',
            }[l]!),
            selected: l == widget.language,
            onSelected: (_) => widget.onLanguage(l),
          ),
      ]),
      const SizedBox(height: 16),
      Text(t('theme'), style: const TextStyle(fontWeight: FontWeight.w600)),
      Wrap(spacing: 8, children: [
        ChoiceChip(
            label: Text(t('theme-systeme')),
            selected: widget.theme == AppThemeMode.system,
            onSelected: (_) => widget.onTheme(AppThemeMode.system)),
        ChoiceChip(
            label: Text(t('theme-clair')),
            selected: widget.theme == AppThemeMode.light,
            onSelected: (_) => widget.onTheme(AppThemeMode.light)),
        ChoiceChip(
            label: Text(t('theme-sombre')),
            selected: widget.theme == AppThemeMode.dark,
            onSelected: (_) => widget.onTheme(AppThemeMode.dark)),
      ]),
      const SizedBox(height: 16),
      Text(t('defs-wikt'),
          style: const TextStyle(fontWeight: FontWeight.w600)),
      SwitchListTile(
        dense: true,
        value: _wiktOnly,
        onChanged: _toggleWikt,
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
          itemCount: widget.order.length,
          onReorder: (oldIndex, newIndex) {
            final list = [...widget.order];
            if (newIndex > oldIndex) newIndex--;
            final e = list.removeAt(oldIndex);
            list.insert(newIndex, e);
            widget.onOrder(list);
          },
          itemBuilder: (context, i) => ListTile(
            key: ValueKey(widget.order[i]),
            dense: true,
            leading: const Icon(Icons.drag_handle),
            title: Text(t(widget.order[i])),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Text(t('sauvegarde'),
          style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Wrap(spacing: 10, children: [
        OutlinedButton.icon(
            onPressed: _export,
            icon: const Icon(Icons.file_upload),
            label: Text(t('sauvegarde-exporter'))),
        OutlinedButton.icon(
            onPressed: _import,
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