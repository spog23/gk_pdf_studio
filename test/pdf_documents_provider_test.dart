import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gk_pdf_studio/controllers/providers/pdf_files_provider.dart';
import 'package:gk_pdf_studio/models/pdf_page.dart';
import 'package:gk_pdf_studio/models/pdf_source_document.dart';

void main() {
  ProviderContainer createContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  PdfSourceDocument createDocument(String path, int pageCount) {
    return PdfSourceDocument(
      sourceFilePath: path,
      pages: List.generate(
        pageCount,
        (index) => PdfPage(pageIndex: index, sourceFilePath: path, rotation: 0),
      ),
    );
  }

  List<String> flattenPageOrder(List<PdfSourceDocument> documents) {
    return [
      for (final document in documents)
        for (final page in document.pages)
          '${page.sourceFilePath}:${page.pageIndex}',
    ];
  }

  test('rotateDocument rotates all pages in the selected document', () {
    final container = createContainer();
    final document = createDocument('file1.pdf', 2);

    container.read(pdfDocumentsProvider.notifier).addDocuments([document]);
    container.read(pdfDocumentsProvider.notifier).rotateDocument(document, 90);

    final updatedDocuments = container.read(pdfDocumentsProvider);

    expect(updatedDocuments.first.pages[0].rotation, 90);
    expect(updatedDocuments.first.pages[1].rotation, 90);
  });

  test('rotatePage rotates only the targeted page', () {
    final container = createContainer();
    final document = createDocument('file1.pdf', 2);

    container.read(pdfDocumentsProvider.notifier).addDocuments([document]);
    container
        .read(pdfDocumentsProvider.notifier)
        .rotatePage(document.pages.first, 90);

    final updatedDocuments = container.read(pdfDocumentsProvider);

    expect(updatedDocuments.first.pages[0].rotation, 90);
    expect(updatedDocuments.first.pages[1].rotation, 0);
  });

  test(
    'deletePage removes a page and undoDelete restores it at the same index',
    () {
      final container = createContainer();
      final document = createDocument('file1.pdf', 3);

      container.read(pdfDocumentsProvider.notifier).addDocuments([document]);
      container
          .read(pdfDocumentsProvider.notifier)
          .deletePage(document.pages[1]);

      final deletedState = container.read(pdfDocumentsProvider);
      expect(deletedState.first.pages.map((page) => page.pageIndex), [0, 2]);

      container.read(pdfDocumentsProvider.notifier).undoDelete();

      final restoredState = container.read(pdfDocumentsProvider);
      expect(restoredState.first.pages.map((page) => page.pageIndex), [
        0,
        1,
        2,
      ]);
      expect(container.read(selectedPageProvider)?.pageIndex, 1);
    },
  );

  test('deletePage removes an empty document and undoDelete restores it', () {
    final container = createContainer();
    final document = createDocument('file1.pdf', 1);

    container.read(pdfDocumentsProvider.notifier).addDocuments([document]);
    container
        .read(pdfDocumentsProvider.notifier)
        .deletePage(document.pages.first);

    expect(container.read(pdfDocumentsProvider), isEmpty);

    container.read(pdfDocumentsProvider.notifier).undoDelete();

    final restoredState = container.read(pdfDocumentsProvider);
    expect(restoredState, hasLength(1));
    expect(restoredState.first.sourceFilePath, 'file1.pdf');
    expect(restoredState.first.pages.map((page) => page.pageIndex), [0]);
  });

  test('another state-changing action clears single-level undo history', () {
    final container = createContainer();
    final document = createDocument('file1.pdf', 2);

    container.read(pdfDocumentsProvider.notifier).addDocuments([document]);
    container
        .read(pdfDocumentsProvider.notifier)
        .deletePage(document.pages.first);
    container
        .read(pdfDocumentsProvider.notifier)
        .rotatePage(document.pages[1], 90);
    container.read(pdfDocumentsProvider.notifier).undoDelete();

    final currentState = container.read(pdfDocumentsProvider);
    expect(currentState.first.pages.map((page) => page.pageIndex), [1]);
    expect(currentState.first.pages.first.rotation, 90);
  });

  test('moving a page invalidates the pending delete undo', () {
    final container = createContainer();
    final document = createDocument('file1.pdf', 3);

    container.read(pdfDocumentsProvider.notifier).addDocuments([document]);
    container
        .read(pdfDocumentsProvider.notifier)
        .deletePage(document.pages.first);

    final remainingPage = container.read(pdfDocumentsProvider).first.pages.last;
    container.read(pdfDocumentsProvider.notifier).movePageUp(remainingPage);
    container.read(pdfDocumentsProvider.notifier).undoDelete();

    expect(flattenPageOrder(container.read(pdfDocumentsProvider)), [
      'file1.pdf:2',
      'file1.pdf:1',
    ]);
  });

  test('importing a new PDF invalidates the pending delete undo', () {
    final container = createContainer();
    final firstDocument = createDocument('file1.pdf', 2);
    final secondDocument = createDocument('file2.pdf', 1);

    container.read(pdfDocumentsProvider.notifier).addDocuments([firstDocument]);
    container
        .read(pdfDocumentsProvider.notifier)
        .deletePage(firstDocument.pages.first);

    container.read(pdfDocumentsProvider.notifier).addDocuments([
      secondDocument,
    ]);
    container.read(pdfDocumentsProvider.notifier).undoDelete();

    expect(flattenPageOrder(container.read(pdfDocumentsProvider)), [
      'file1.pdf:1',
      'file2.pdf:0',
    ]);
  });

  test('clearAll invalidates the pending delete undo', () {
    final container = createContainer();
    final document = createDocument('file1.pdf', 2);

    container.read(pdfDocumentsProvider.notifier).addDocuments([document]);
    container
        .read(pdfDocumentsProvider.notifier)
        .deletePage(document.pages.first);

    container.read(pdfDocumentsProvider.notifier).clearAll();
    container.read(pdfDocumentsProvider.notifier).undoDelete();

    expect(container.read(pdfDocumentsProvider), isEmpty);
  });

  test('movePageUp swaps with the previous flat page and keeps selection', () {
    final container = createContainer();
    final firstDocument = createDocument('file1.pdf', 2);
    final secondDocument = createDocument('file2.pdf', 1);
    final targetPage = secondDocument.pages.first;

    container.read(pdfDocumentsProvider.notifier).addDocuments([
      firstDocument,
      secondDocument,
    ]);
    container.read(selectedPageProvider.notifier).select(targetPage);

    container.read(pdfDocumentsProvider.notifier).movePageUp(targetPage);

    final updatedState = container.read(pdfDocumentsProvider);
    expect(flattenPageOrder(updatedState), [
      'file1.pdf:0',
      'file2.pdf:0',
      'file1.pdf:1',
    ]);
    expect(container.read(selectedPageProvider)?.sourceFilePath, 'file2.pdf');
    expect(container.read(selectedPageProvider)?.pageIndex, 0);
  });

  test('movePageDown swaps with the next flat page and keeps selection', () {
    final container = createContainer();
    final firstDocument = createDocument('file1.pdf', 2);
    final secondDocument = createDocument('file2.pdf', 1);
    final targetPage = firstDocument.pages[1];

    container.read(pdfDocumentsProvider.notifier).addDocuments([
      firstDocument,
      secondDocument,
    ]);
    container.read(selectedPageProvider.notifier).select(targetPage);

    container.read(pdfDocumentsProvider.notifier).movePageDown(targetPage);

    final updatedState = container.read(pdfDocumentsProvider);
    expect(flattenPageOrder(updatedState), [
      'file1.pdf:0',
      'file2.pdf:0',
      'file1.pdf:1',
    ]);
    expect(container.read(selectedPageProvider)?.sourceFilePath, 'file1.pdf');
    expect(container.read(selectedPageProvider)?.pageIndex, 1);
  });
}
