/* Shortcuts: a grid of tiles to websites, stored locally.
   Simplified port of js/outils/raccourcis.js. SPDX-License-Identifier: MIT. */
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n.dart';

class Shortcut {
  String name;
  String url;
  Shortcut(this.name, this.url);

  String get domain {
    final u = Uri.tryParse(url);
    return u?.host ?? url;
  }
}

Future<List<Shortcut>> readShortcuts() async {
  final p = await SharedPreferences.getInstance();
  final raw = p.getStringList('raccourcis') ?? const [];
  return raw.map((c) {
    final k = c.indexOf(' ');
    return k < 0
        ? Shortcut('', c)
        : Shortcut(c.substring(0, k), c.substring(k + 1));
  }).toList();
}

Future<void> writeShortcuts(List<Shortcut> list) async {
  final p = await SharedPreferences.getInstance();
  await p.setStringList(
      'raccourcis', list.map((r) => '${r.name} ${r.url}').toList());
}

class ShortcutsScreen extends StatefulWidget {
  final Translator trad;
  const ShortcutsScreen(this.trad, {super.key});

  @override
  State<ShortcutsScreen> createState() => _ShortcutsScreenState();
}

class _ShortcutsScreenState extends State<ShortcutsScreen> {
  List<Shortcut>? _list;

  @override
  void initState() {
    super.initState();
    readShortcuts().then((l) {
      if (mounted) setState(() => _list = l);
    });
  }

  Future<void> _save() async {
    if (_list != null) await writeShortcuts(_list!);
  }

  Future<void> _edit([int? index]) async {
    final name = TextEditingController();
    final url = TextEditingController();
    if (index != null && _list != null && index < _list!.length) {
      name.text = _list![index].name;
      url.text = _list![index].url;
    }
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            index == null ? widget.trad('ajouter') : widget.trad('editer')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: name,
            decoration: InputDecoration(labelText: widget.trad('nom')),
          ),
          TextField(
            controller: url,
            decoration: InputDecoration(labelText: widget.trad('adresse')),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
    {
      final u = url.text.trim();
      if (u.isEmpty) return;
      final fresh = Shortcut(name.text.trim(), u);
      setState(() {
        if (index != null && _list != null && index < _list!.length) {
          _list![index] = fresh;
        } else {
          _list = [..._list ?? const [], fresh];
        }
      });
      await _save();
    }
  }

  /* context menu: edit or delete the shortcut */
  Future<void> _menu(int i) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: Text(widget.trad('editer')),
            onTap: () => Navigator.pop(context, 'editer'),
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: Text(widget.trad('supprimer')),
            onTap: () => Navigator.pop(context, 'supprimer'),
          ),
        ]),
      ),
    );
    if (choice == 'editer') {
      await _edit(i);
    } else if (choice == 'supprimer') {
      setState(() => _list!.removeAt(i));
      await _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_list == null) return const Center(child: CircularProgressIndicator());
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < _list!.length; i++)
          InkWell(
            onLongPress: () => _menu(i),
            onTap: () async {
              final u = Uri.tryParse(_list![i].url);
              if (u != null && await canLaunchUrl(u)) await launchUrl(u);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(children: [
                Text(
                    _list![i].name.isEmpty
                        ? _list![i].domain
                        : _list![i].name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ActionChip(
          label: Text(widget.trad('ajouter')),
          onPressed: () => _edit(),
        ),
      ],
    );
  }
}