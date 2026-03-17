import 'dart:io';
import 'dart:ui';

import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models/pdf_file.dart';

class PdfService {
  Future<File> mergePdfFiles(List<PdfFile> files, String outputPath) async {
    if (files.isEmpty) {
      throw ArgumentError('At least one PDF file is required for merging.');
    }

    if (outputPath.isEmpty) {
      throw ArgumentError('An output file path is required for merging.');
    }

    final outputDocument = PdfDocument();
    outputDocument.pageSettings.margins.all = 0;

    final loadedDocuments = <PdfDocument>[];

    try {
      for (final file in files) {
        final inputFile = File(file.path);

        if (!await inputFile.exists()) {
          throw FileSystemException('PDF file not found.', file.path);
        }

        final bytes = await inputFile.readAsBytes();
        final loadedDocument = PdfDocument(inputBytes: bytes);
        loadedDocuments.add(loadedDocument);

        for (var pageIndex = 0; pageIndex < loadedDocument.pages.count; pageIndex++) {
          final sourcePage = loadedDocument.pages[pageIndex];
          final pageSize = sourcePage.size;
          final pageTemplate = sourcePage.createTemplate();

          outputDocument.pageSettings.size = Size(pageSize.width, pageSize.height);
          final outputPage = outputDocument.pages.add();
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
      for (final document in loadedDocuments) {
        document.dispose();
      }
      outputDocument.dispose();
    }
  }
}
