/* Saving a file produced by the app, cross-platform.
   - desktop: native system dialog ( file_selector, getSaveLocation );
   - Android: getSaveLocation is not implemented there by file_selector;
     the file is then written to the app storage and offered through the
     system share sheet ( save to Downloads, Drive, e-mail... );
   - any other platform without a dialog: documents folder of the app.
   SPDX-License-Identifier: MIT. */
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

/* Writes [bytes] to a file named [name]. Returns false if the user
   cancels; throws on a write error. */
Future<bool> saveBytes(String name, List<int> bytes) async {
  final ext = name.contains('.')
      ? name.substring(name.lastIndexOf('.') + 1).toLowerCase()
      : '';
  if (!kIsWeb && Platform.isAndroid) {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    final res = await Share.shareXFiles([
      XFile(file.path, mimeType: _mimes[ext] ?? 'application/octet-stream')
    ]);
    return res.status == ShareResultStatus.success;
  }
  try {
    final location = await getSaveLocation(
      suggestedName: name,
      acceptedTypeGroups: ext.isEmpty
          ? const <XTypeGroup>[]
          : [
              XTypeGroup(label: ext.toUpperCase(), extensions: [ext]),
            ],
    );
    if (location == null) return false;
    await File(location.path).writeAsBytes(bytes, flush: true);
    return true;
  } on UnimplementedError {
    final dir = await getApplicationDocumentsDirectory();
    await File('${dir.path}/$name').writeAsBytes(bytes, flush: true);
    return true;
  }
}

/* Text variant: encodes to UTF-8 then saves. */
Future<bool> saveText(String name, String text) =>
    saveBytes(name, utf8.encode(text));