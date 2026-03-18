import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sfpdf;

import '../models/pdf_page.dart';
import '../models/pdf_source_document.dart';

class PdfFileImportService {
  Future<List<PdfSourceDocument>> pickPdfDocuments() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      dialogTitle: 'Import PDF files',
    );

    if (result == null) {
      return const [];
    }

    final paths = result.files
        .where((file) => file.path != null)
        .where((file) => file.extension?.toLowerCase() == 'pdf')
        .map((file) => file.path!)
        .toList(growable: false);

    return loadDocumentsFromPaths(paths);
  }

  Future<List<PdfSourceDocument>> loadDocumentsFromPaths(List<String> paths) async {
    final documents = <PdfSourceDocument>[];

    for (final path in paths) {
      final inputFile = File(path);

      if (!await inputFile.exists()) {
        continue;
      }

      final bytes = await inputFile.readAsBytes();
      final loadedDocument = sfpdf.PdfDocument(inputBytes: bytes);

      try {
        final pages = List.generate(
          loadedDocument.pages.count,
          (index) => PdfPage(
            pageIndex: index,
            sourceFilePath: path,
            rotation: 0,
          ),
          growable: false,
        );

        documents.add(
          PdfSourceDocument(
            pages: pages,
            sourceFilePath: path,
          ),
        );
      } finally {
        loadedDocument.dispose();
      }
    }

    return List.unmodifiable(documents);
  }
}
