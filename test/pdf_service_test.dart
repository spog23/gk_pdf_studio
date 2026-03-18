import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sfpdf;

import 'package:gk_pdf_studio/controllers/providers/pdf_files_provider.dart';
import 'package:gk_pdf_studio/models/pdf_page.dart';
import 'package:gk_pdf_studio/models/pdf_source_document.dart';
import 'package:gk_pdf_studio/services/pdf_service.dart';

void main() {
  test(
    'mergePdfFiles keeps pages unrotated when no rotation is applied',
    () async {
      final pdfService = PdfService();
      final sourceFiles = <File>[];

      Future<File> createPdfFile(String name) async {
        final document = sfpdf.PdfDocument();
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

      PdfSourceDocument createImportedDocument(File file) {
        return PdfSourceDocument(
          sourceFilePath: file.path,
          pages: [
            PdfPage(pageIndex: 0, sourceFilePath: file.path, rotation: 0),
          ],
        );
      }

      final firstFile = await createPdfFile('merge_source_1.pdf');
      final secondFile = await createPdfFile('merge_source_2.pdf');
      final mergedFilePath =
          '${Directory.systemTemp.path}${Platform.pathSeparator}merged_test_output.pdf';

      final mergedFile = await pdfService.mergePdfFiles([
        createImportedDocument(firstFile),
        createImportedDocument(secondFile),
      ], mergedFilePath);

      expect(await mergedFile.exists(), isTrue);

      final mergedBytes = await mergedFile.readAsBytes();
      final mergedDocument = sfpdf.PdfDocument(inputBytes: mergedBytes);

      expect(mergedDocument.pages.count, 2);
      expect(
        mergedDocument.pages[0].rotation,
        sfpdf.PdfPageRotateAngle.rotateAngle0,
      );
      expect(
        mergedDocument.pages[1].rotation,
        sfpdf.PdfPageRotateAngle.rotateAngle0,
      );

      mergedDocument.dispose();
      await mergedFile.delete();

      for (final file in sourceFiles) {
        if (await file.exists()) {
          await file.delete();
        }
      }
    },
  );

  test('mergePdfFiles applies rotation to only the selected page', () async {
    final pdfService = PdfService();
    final sourceFile = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}single_page_rotate.pdf',
    );
    final outputFile = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}single_page_rotate_output.pdf',
    );

    final document = sfpdf.PdfDocument();
    document.pages.add();
    document.pages.add();
    final bytes = await document.save();
    document.dispose();
    await sourceFile.writeAsBytes(bytes, flush: true);

    final mergedFile = await pdfService.mergePdfFiles([
      PdfSourceDocument(
        sourceFilePath: sourceFile.path,
        pages: [
          PdfPage(pageIndex: 0, sourceFilePath: sourceFile.path, rotation: 90),
          PdfPage(pageIndex: 1, sourceFilePath: sourceFile.path, rotation: 0),
        ],
      ),
    ], outputFile.path);

    final mergedDocument = sfpdf.PdfDocument(
      inputBytes: await mergedFile.readAsBytes(),
    );

    expect(
      mergedDocument.pages[0].rotation,
      sfpdf.PdfPageRotateAngle.rotateAngle90,
    );
    expect(
      mergedDocument.pages[1].rotation,
      sfpdf.PdfPageRotateAngle.rotateAngle0,
    );

    mergedDocument.dispose();
    await mergedFile.delete();
    await sourceFile.delete();
  });

  test('mergePdfFiles applies rotation to all pages in a document', () async {
    final pdfService = PdfService();
    final sourceFile = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}document_rotate.pdf',
    );
    final outputFile = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}document_rotate_output.pdf',
    );

    final document = sfpdf.PdfDocument();
    document.pages.add();
    document.pages.add();
    final bytes = await document.save();
    document.dispose();
    await sourceFile.writeAsBytes(bytes, flush: true);

    final mergedFile = await pdfService.mergePdfFiles([
      PdfSourceDocument(
        sourceFilePath: sourceFile.path,
        pages: [
          PdfPage(pageIndex: 0, sourceFilePath: sourceFile.path, rotation: 90),
          PdfPage(pageIndex: 1, sourceFilePath: sourceFile.path, rotation: 90),
        ],
      ),
    ], outputFile.path);

    final mergedDocument = sfpdf.PdfDocument(
      inputBytes: await mergedFile.readAsBytes(),
    );

    expect(
      mergedDocument.pages[0].rotation,
      sfpdf.PdfPageRotateAngle.rotateAngle90,
    );
    expect(
      mergedDocument.pages[1].rotation,
      sfpdf.PdfPageRotateAngle.rotateAngle90,
    );

    mergedDocument.dispose();
    await mergedFile.delete();
    await sourceFile.delete();
  });

  test(
    'mergePdfFiles respects reordered, rotated, and deleted page state',
    () async {
      final pdfService = PdfService();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final sourceFiles = <File>[];

      Future<File> createPdfFile(String name) async {
        final document = sfpdf.PdfDocument();
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

      PdfSourceDocument createImportedDocument(File file) {
        return PdfSourceDocument(
          sourceFilePath: file.path,
          pages: [PdfPage(pageIndex: 0, sourceFilePath: file.path)],
        );
      }

      final firstFile = await createPdfFile('reorder_source_1.pdf');
      final secondFile = await createPdfFile('reorder_source_2.pdf');
      final thirdFile = await createPdfFile('reorder_source_3.pdf');
      final outputPath =
          '${Directory.systemTemp.path}${Platform.pathSeparator}reorder_export_output.pdf';

      final firstDocument = createImportedDocument(firstFile);
      final secondDocument = createImportedDocument(secondFile);
      final thirdDocument = createImportedDocument(thirdFile);

      container.read(pdfDocumentsProvider.notifier).addDocuments([
        firstDocument,
        secondDocument,
        thirdDocument,
      ]);
      container
          .read(pdfDocumentsProvider.notifier)
          .rotatePage(secondDocument.pages.first, 180);
      container
          .read(pdfDocumentsProvider.notifier)
          .movePageUp(thirdDocument.pages.first);
      container
          .read(pdfDocumentsProvider.notifier)
          .rotatePage(thirdDocument.pages.first, 90);
      container
          .read(pdfDocumentsProvider.notifier)
          .deletePage(firstDocument.pages.first);

      final mergedFile = await pdfService.mergePdfFiles(
        container.read(pdfDocumentsProvider),
        outputPath,
      );
      final mergedDocument = sfpdf.PdfDocument(
        inputBytes: await mergedFile.readAsBytes(),
      );

      expect(mergedDocument.pages.count, 2);
      expect(
        mergedDocument.pages[0].rotation,
        sfpdf.PdfPageRotateAngle.rotateAngle90,
      );
      expect(
        mergedDocument.pages[1].rotation,
        sfpdf.PdfPageRotateAngle.rotateAngle180,
      );

      mergedDocument.dispose();
      await mergedFile.delete();

      for (final file in sourceFiles) {
        if (await file.exists()) {
          await file.delete();
        }
      }
    },
  );
}
