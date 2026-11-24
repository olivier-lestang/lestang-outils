/* Compression de PDF : le fichier est rastérise page par page via pdfium
   ( package printing ), encode en JPEG ( package image ), puis reconstruit
   en PDF ( package pdf ). Les bibliotheques performances preferes aux
   bibliotheques legeres du web, tutes sous licence MIT ou apparentee Apache.
   SPDX-License-Identifier : MIT. */
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../l10n.dart';
import '../sauvegarde.dart';

String _tailleHumaine(int octets) {
  if (octets < 1024) return '$octets o';
  if (octets < 1024 * 1024) return '${(octets / 1024).toStringAsFixed(0)} Ko';
  return '${(octets / 1024 / 1024).toStringAsFixed(2)} Mo';
}

class EcranPdf extends StatefulWidget {
  final Traducteur trad;
  const EcranPdf(this.trad, {super.key});

  @override
  State<EcranPdf> createState() => _EcranPdfState();
}

class _EcranPdfState extends State<EcranPdf> {
  int _dpi = 150;
  int _qualite = 70;
  bool _occupe = false;
  String _resultat = '';

  @override
  Widget build(BuildContext context) {
    final t = widget.trad;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(t('pdf-titre'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      SizedBox(
        width: 520,
        child: Text(t('pdf-aide'),
            style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ),
      const SizedBox(height: 14),
      Row(children: [
        Text('${t('pdf-dpi')} : '),
        DropdownButton<int>(
          value: _dpi,
          items: const [
            DropdownMenuItem(value: 72, child: Text('72')),
            DropdownMenuItem(value: 96, child: Text('96')),
            DropdownMenuItem(value: 150, child: Text('150')),
            DropdownMenuItem(value: 220, child: Text('220')),
          ],
          onChanged: (v) => setState(() => _dpi = v ?? _dpi),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Row(children: [
            Text('${t('pdf-qualite')} : '),
            Expanded(
              child: Slider(
                value: _qualite.toDouble(),
                min: 30,
                max: 95,
                divisions: 13,
                label: '$_qualite',
                onChanged: (v) => setState(() => _qualite = v.round()),
              ),
            ),
            SizedBox(width: 40, child: Text('$_qualite')),
          ]),
        ),
      ]),
      const SizedBox(height: 10),
      Wrap(spacing: 10, runSpacing: 8, children: [
        FilledButton.icon(
          onPressed: _occupe ? null : _compresser,
          icon: const Icon(Icons.compress),
          label: Text(t('pdf-choisir')),
        ),
        if (_occupe)
          const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2)),
      ]),
      if (_resultat.isNotEmpty) ...[
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(_resultat, style: const TextStyle(fontSize: 13)),
        ),
      ],
    ]);
  }

  Future<void> _compresser() async {
    final t = widget.trad;
    final fichier = await openFile(acceptedTypeGroups: const [
      XTypeGroup(label: 'PDF', extensions: ['pdf'])
    ]);
    if (fichier == null) return;
    final entree = File(fichier.path);
    final octetsEntree = await entree.readAsBytes();
    setState(() {
      _occupe = true;
      _resultat = '';
    });
    try {
      final doc = pw.Document();
      var pages = 0;
      await for (final page
          in Printing.raster(octetsEntree, dpi: _dpi.toDouble())) {
        final png = await page.toPng();
        final image = img.decodePng(png);
        if (image == null) continue;
        final jpg = img.encodeJpg(image, quality: _qualite);
        final w = page.width * 72.0 / _dpi;
        final h = page.height * 72.0 / _dpi;
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(w, h),
            margin: pw.EdgeInsets.zero,
            build: (c) => pw.Center(
                child: pw.Image(pw.MemoryImage(jpg), fit: pw.BoxFit.cover)),
          ),
        );
        pages++;
      }
      if (pages == 0) throw Exception(t('pdf-erreur'));
      final octetsSortie = await doc.save();
      final sauve = await enregistrerOctets('compressé.pdf', octetsSortie);
      if (sauve && mounted) {
        setState(() {
          _resultat = '$pages ${t('pdf-pages')}\n'
              '${t('pdf-avant')} : ${_tailleHumaine(octetsEntree.length)} → '
              '${t('pdf-apres')} : ${_tailleHumaine(octetsSortie.length)} '
              '(${(100 - octetsSortie.length * 100 / octetsEntree.length).toStringAsFixed(0)} % ${t('pdf-gagne')})';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _resultat = '${t('pdf-erreur')} ($e)');
    } finally {
      if (mounted) setState(() => _occupe = false);
    }
  }
}
