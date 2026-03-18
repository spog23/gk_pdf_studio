import 'dart:io';
import 'dart:ui';

import 'package:syncfusion_flutter_pdf/pdf.dart' as sfpdf;

import '../models/pdf_source_document.dart';

class PdfService {
  Future<File> mergePdfFiles(
    List<PdfSourceDocument> documents,
    String outputPath,
  ) async {
    if (documents.isEmpty) {
      throw ArgumentError('At least one PDF file is required for merging.');
    }

    if (outputPath.isEmpty) {
      throw ArgumentError('An output file path is required for merging.');
    }

    final outputDocument = sfpdf.PdfDocument();
    outputDocument.pageSettings.margins.all = 0;

    final loadedDocuments = <String, sfpdf.PdfDocument>{};

    try {
      for (final document in documents) {
        final loadedDocument = await _loadDocument(
          document.sourceFilePath,
          loadedDocuments,
        );

        for (final page in document.pages) {
          final sourcePage = loadedDocument.pages[page.pageIndex];
          final pageSize = sourcePage.size;
          final pageTemplate = sourcePage.createTemplate();

          final pageSettings = sfpdf.PdfPageSettings(
            Size(pageSize.width, pageSize.height),
          );
          pageSettings.margins.all = 0;
          pageSettings.rotate = _mapRotation(page.rotation);

          final section = outputDocument.sections!.add();
          section.pageSettings = pageSettings;

          final outputPage = section.pages.add();
          outputPage.graphics.drawPdfTemplate(
            pageTemplate,
            Offset.zero,
            pageSize,
          );
        }
      }

      final outputFile = File(outputPath);
      final outputBytes = await outputDocument.save();

      await outputFile.writeAsBytes(outputBytes, flush: true);
      return outputFile;
    } finally {
      for (final document in loadedDocuments.values) {
        document.dispose();
      }
      outputDocument.dispose();
    }
  }

  Future<sfpdf.PdfDocument> _loadDocument(
    String sourceFilePath,
    Map<String, sfpdf.PdfDocument> cache,
  ) async {
    final cachedDocument = cache[sourceFilePath];
    if (cachedDocument != null) {
      return cachedDocument;
    }

    final inputFile = File(sourceFilePath);

    if (!await inputFile.exists()) {
      throw FileSystemException('PDF file not found.', sourceFilePath);
    }

    final bytes = await inputFile.readAsBytes();
    final loadedDocument = sfpdf.PdfDocument(inputBytes: bytes);
    cache[sourceFilePath] = loadedDocument;
    return loadedDocument;
  }

  sfpdf.PdfPageRotateAngle _mapRotation(int degrees) {
    switch (degrees % 360) {
      case 90:
        return sfpdf.PdfPageRotateAngle.rotateAngle90;
      case 180:
        return sfpdf.PdfPageRotateAngle.rotateAngle180;
      case 270:
        return sfpdf.PdfPageRotateAngle.rotateAngle270;
      case 0:
      default:
        return sfpdf.PdfPageRotateAngle.rotateAngle0;
    }
  }
}
