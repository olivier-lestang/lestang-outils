/* Enregistrement d un fichier produit par l app, multiplateformes.
   - bureau : boite de dialogue native du systeme ( file_selector,
     getSaveLocation ) ;
   - Android : getSaveLocation n y est pas implemente par file_selector ;
     le fichier est alors ecrit dans le stockage de l app et propose
     via la feuille de partage du systeme ( enregistrer dans
     Telechargements, Drive, e-mail... ) ;
   - toute autre plateforme sans dialogue : dossier documents de l app.
   SPDX-License-Identifier : MIT. */
import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

const _mimes = {
  'pdf': 'application/pdf',
  'json': 'application/json',
};

/* Ecrit [octets] dans un fichier de nom [nom]. Retourne false si
   l utilisateur annule ; leve une exception en cas d erreur d ecriture. */
Future<bool> enregistrerOctets(String nom, List<int> octets) async {
  final ext = nom.contains('.')
      ? nom.substring(nom.lastIndexOf('.') + 1).toLowerCase()
      : '';
  if (!kIsWeb && Platform.isAndroid) {
    final rep = await getTemporaryDirectory();
    final fichier = File('${rep.path}/$nom');
    await fichier.writeAsBytes(octets, flush: true);
    final res = await Share.shareXFiles([
      XFile(fichier.path,
          mimeType: _mimes[ext] ?? 'application/octet-stream')
    ]);
    return res.status == ShareResultStatus.success;
  }
  try {
    final lieu = await getSaveLocation(
      suggestedName: nom,
      acceptedTypeGroups: ext.isEmpty
          ? null
          : [
              XTypeGroup(label: ext.toUpperCase(), extensions: [ext]),
            ],
    );
    if (lieu == null) return false;
    await File(lieu.path).writeAsBytes(octets, flush: true);
    return true;
  } on UnimplementedError {
    final rep = await getApplicationDocumentsDirectory();
    await File('${rep.path}/$nom').writeAsBytes(octets, flush: true);
    return true;
  }
}

/* Variante texte : encode en UTF-8 puis enregistre. */
Future<bool> enregistrerTexte(String nom, String texte) =>
    enregistrerOctets(nom, utf8.encode(texte));
