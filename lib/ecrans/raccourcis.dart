/* Raccourcis : une grille de tuiles vers des sites, stockee localement.
   Portage simplifié de js/outils/raccourcis.js. SPDX-License-Identifier : MIT. */
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n.dart';

class Raccourci {
  String nom;
  String url;
  Raccourci(this.nom, this.url);

  String get domaine {
    final u = Uri.tryParse(url);
    return u?.host ?? url;
  }
}

Future<List<Raccourci>> lireRaccourcis() async {
  final p = await SharedPreferences.getInstance();
  final crus = p.getStringList('raccourcis') ?? const [];
  return crus.map((c) {
    final k = c.indexOf(' ');
    return k < 0
        ? Raccourci('', c)
        : Raccourci(c.substring(0, k), c.substring(k + 1));
  }).toList();
}

Future<void> ecrireRaccourcis(List<Raccourci> liste) async {
  final p = await SharedPreferences.getInstance();
  await p.setStringList(
      'raccourcis', liste.map((r) => '${r.nom} ${r.url}').toList());
}

class EcranRaccourcis extends StatefulWidget {
  final Traducteur trad;
  const EcranRaccourcis(this.trad, {super.key});

  @override
  State<EcranRaccourcis> createState() => _EcranRaccourcisState();
}

class _EcranRaccourcisState extends State<EcranRaccourcis> {
  List<Raccourci>? _liste;

  @override
  void initState() {
    super.initState();
    lireRaccourcis().then((l) {
      if (mounted) setState(() => _liste = l);
    });
  }

  Future<void> _sauver() async {
    if (_liste != null) await ecrireRaccourcis(_liste!);
  }

  Future<void> _editer([int? index]) async {
    final nom = TextEditingController();
    final url = TextEditingController();
    if (index != null && _liste != null && index < _liste!.length) {
      nom.text = _liste![index].nom;
      url.text = _liste![index].url;
    }
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            index == null ? widget.trad('ajouter') : widget.trad('editer')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: nom,
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
      final nouveau = Raccourci(nom.text.trim(), u);
      setState(() {
        if (index != null && _liste != null && index < _liste!.length) {
          _liste![index] = nouveau;
        } else {
          _liste = [..._liste ?? const [], nouveau];
        }
      });
      await _sauver();
    }
  }

  /* menu contextuel : editer ou supprimer le raccourci */
  Future<void> _menu(int i) async {
    final choix = await showModalBottomSheet<String>(
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
    if (choix == 'editer') {
      await _editer(i);
    } else if (choix == 'supprimer') {
      setState(() => _liste!.removeAt(i));
      await _sauver();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_liste == null) return const Center(child: CircularProgressIndicator());
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < _liste!.length; i++)
          InkWell(
            onLongPress: () => _menu(i),
            onTap: () async {
              final u = Uri.tryParse(_liste![i].url);
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
                    _liste![i].nom.isEmpty
                        ? _liste![i].domaine
                        : _liste![i].nom,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ActionChip(
          label: Text(widget.trad('ajouter')),
          onPressed: () => _editer(),
        ),
      ],
    );
  }
}
