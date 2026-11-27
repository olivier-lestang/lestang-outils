/* PDF compression: the file is rasterised page by page via pdfium
   ( package printing ), encoded to JPEG ( package image ), then rebuilt
   as a PDF ( package pdf ). The performance libraries preferred to the
   lightweight libraries of the web, all under an MIT or related Apache
   license. SPDX-License-Identifier: MIT. */
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../backup.dart';
import '../l10n.dart';

String _humanSize(int bytes) {
  if (bytes < 1024) return '$bytes o';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} Ko';
  return '${(bytes / 1024 / 1024).toStringAsFixed(2)} Mo';
}

class PdfScreen extends StatefulWidget {
  final Translator translator;
  const PdfScreen(this.translator, {super.key});

  @override
  State<PdfScreen> createState() => _PdfScreenState();
}

class _PdfScreenState extends State<PdfScreen> {
  int _dpi = 150;
  int _quality = 70;
  bool _busy = false;
  String _result = '';

  @override
  Widget build(BuildContext context) {
    final t = widget.translator;
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
                value: _quality.toDouble(),
                min: 30,
                max: 95,
                divisions: 13,
                label: '$_quality',
                onChanged: (v) => setState(() => _quality = v.round()),
              ),
            ),
            SizedBox(width: 40, child: Text('$_quality')),
          ]),
        ),
      ]),
      const SizedBox(height: 10),
      Wrap(spacing: 10, runSpacing: 8, children: [
        FilledButton.icon(
          onPressed: _busy ? null : _compress,
          icon: const Icon(Icons.compress),
          label: Text(t('pdf-choisir')),
        ),
        if (_busy)
          const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2)),
      ]),
      if (_result.isNotEmpty) ...[
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(_result, style: const TextStyle(fontSize: 13)),
        ),
      ],
    ]);
  }

  Future<void> _compress() async {
    final t = widget.translator;
    final file = await openFile(acceptedTypeGroups: const [
      XTypeGroup(label: 'PDF', extensions: ['pdf'])
    ]);
    if (file == null) return;
    final input = File(file.path);
    final inputBytes = await input.readAsBytes();
    setState(() {
      _busy = true;
      _result = '';
    });
    try {
      final doc = pw.Document();
      var pages = 0;
      await for (final page
          in Printing.raster(inputBytes, dpi: _dpi.toDouble())) {
        final png = await page.toPng();
        final image = img.decodePng(png);
        if (image == null) continue;
        final jpg = img.encodeJpg(image, quality: _quality);
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
      final outputBytes = await doc.save();
      final saved = await saveBytes('compressé.pdf', outputBytes);
      if (saved && mounted) {
        setState(() {
          _result = '$pages ${t('pdf-pages')}\n'
              '${t('pdf-avant')} : ${_humanSize(inputBytes.length)} → '
              '${t('pdf-apres')} : ${_humanSize(outputBytes.length)} '
              '(${(100 - outputBytes.length * 100 / inputBytes.length).toStringAsFixed(0)} % ${t('pdf-gagne')})';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _result = '${t('pdf-erreur')} ($e)');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
