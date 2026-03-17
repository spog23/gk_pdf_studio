import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'package:gk_pdf_studio/models/pdf_file.dart';
import 'package:gk_pdf_studio/services/pdf_service.dart';

void main() {
  test('mergePdfFiles combines multiple PDFs into one output file', () async {
    final pdfService = PdfService();
    final sourceFiles = <File>[];

    Future<File> createPdfFile(String name) async {
      final document = PdfDocument();
      document.pages.add();
      final bytes = await document.save();
      document.dispose();

      final file = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}$name',
      );
      await file.writeAsBytes(bytes, flush: true);
      sourceFiles.add(file);
      return file;
    }

    final firstFile = await createPdfFile('merge_source_1.pdf');
    final secondFile = await createPdfFile('merge_source_2.pdf');
    final mergedFilePath =
        '${Directory.systemTemp.path}${Platform.pathSeparator}merged_test_output.pdf';

    final mergedFile = await pdfService.mergePdfFiles([
      PdfFile(name: 'merge_source_1.pdf', path: firstFile.path),
      PdfFile(name: 'merge_source_2.pdf', path: secondFile.path),
    ], mergedFilePath);

    expect(await mergedFile.exists(), isTrue);

    final mergedBytes = await mergedFile.readAsBytes();
    final mergedDocument = PdfDocument(inputBytes: mergedBytes);

    expect(mergedDocument.pages.count, 2);

    mergedDocument.dispose();
    await mergedFile.delete();

    for (final file in sourceFiles) {
      if (await file.exists()) {
        await file.delete();
      }
    }
  });
}
