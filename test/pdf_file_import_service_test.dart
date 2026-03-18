import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sfpdf;

import 'package:gk_pdf_studio/services/pdf_file_import_service.dart';

void main() {
  test('loadDocumentsFromPaths creates logical pages for an imported PDF', () async {
    final importService = PdfFileImportService();
    final sourceFile =
        File('${Directory.systemTemp.path}${Platform.pathSeparator}import_source.pdf');

    final document = sfpdf.PdfDocument();
    document.pages.add();
    document.pages.add();
    final bytes = await document.save();
    document.dispose();

    await sourceFile.writeAsBytes(bytes, flush: true);

    final importedDocuments = await importService.loadDocumentsFromPaths([
      sourceFile.path,
    ]);

    expect(importedDocuments, hasLength(1));
    expect(importedDocuments.first.sourceFilePath, sourceFile.path);
    expect(importedDocuments.first.pages, hasLength(2));
    expect(importedDocuments.first.pages.first.pageIndex, 0);
    expect(importedDocuments.first.pages.last.pageIndex, 1);
    expect(importedDocuments.first.pages.first.rotation, 0);
    expect(importedDocuments.first.pages.first.sourceFilePath, sourceFile.path);

    await sourceFile.delete();
  });
}
