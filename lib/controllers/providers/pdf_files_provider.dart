import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/pdf_page.dart';
import '../../models/pdf_source_document.dart';
import '../../services/pdf_file_import_service.dart';

final pdfImportServiceProvider = Provider<PdfFileImportService>((ref) {
  return PdfFileImportService();
});

final selectedPageProvider = NotifierProvider<SelectedPageNotifier, PdfPage?>(
  SelectedPageNotifier.new,
);

final selectedDocumentProvider =
    NotifierProvider<SelectedDocumentNotifier, PdfSourceDocument?>(
      SelectedDocumentNotifier.new,
    );

final lastDeletedPageActionProvider =
    NotifierProvider<LastDeletedPageActionNotifier, DeletedPageAction?>(
      LastDeletedPageActionNotifier.new,
    );

final pdfDocumentsProvider =
    NotifierProvider<PdfDocumentsNotifier, List<PdfSourceDocument>>(
      PdfDocumentsNotifier.new,
    );

class SelectedPageNotifier extends Notifier<PdfPage?> {
  @override
  PdfPage? build() {
    return null;
  }

  void select(PdfPage page) {
    state = page;
  }

  void clear() {
    state = null;
  }
}

class SelectedDocumentNotifier extends Notifier<PdfSourceDocument?> {
  @override
  PdfSourceDocument? build() {
    return null;
  }

  void select(PdfSourceDocument document) {
    state = document;
  }

  void clear() {
    state = null;
  }
}

class DeletedPageAction {
  const DeletedPageAction({
    required this.lastDeletedPage,
    required this.originalFlatPageIndex,
  });

  final PdfPage lastDeletedPage;
  final int originalFlatPageIndex;
}

class LastDeletedPageActionNotifier extends Notifier<DeletedPageAction?> {
  @override
  DeletedPageAction? build() {
    return null;
  }

  void store(DeletedPageAction action) {
    state = action;
  }

  void clear() {
    state = null;
  }
}

class PdfDocumentsNotifier extends Notifier<List<PdfSourceDocument>> {
  @override
  List<PdfSourceDocument> build() {
    return const [];
  }

  void addDocuments(List<PdfSourceDocument> documents) {
    if (documents.isEmpty) {
      return;
    }

    final nextDocuments = [...state];

    for (final document in documents) {
      final alreadyExists = nextDocuments.any(
        (existingDocument) =>
            existingDocument.sourceFilePath == document.sourceFilePath,
      );

      if (!alreadyExists) {
        nextDocuments.add(document);
      }
    }

    state = List.unmodifiable(nextDocuments);
    clearDeleteHistory();
  }

  void rotatePage(PdfPage page, int degrees) {
    state = [
      for (final document in state)
        if (document.pages.any(
          (documentPage) => _isSamePage(documentPage, page),
        ))
          document.copyWith(
            pages: [
              for (final documentPage in document.pages)
                if (_isSamePage(documentPage, page))
                  documentPage.copyWith(
                    rotation: _nextRotation(documentPage.rotation, degrees),
                  )
                else
                  documentPage,
            ],
          )
        else
          document,
    ];

    _selectPageAndContainingDocument(page);
    clearDeleteHistory();
  }

  void rotateDocument(PdfSourceDocument document, int degrees) {
    state = [
      for (final currentDocument in state)
        if (_isSameDocument(currentDocument, document))
          currentDocument.copyWith(
            pages: [
              for (final page in currentDocument.pages)
                page.copyWith(rotation: _nextRotation(page.rotation, degrees)),
            ],
          )
        else
          currentDocument,
    ];

    final updatedDocument = _findMatchingDocument(document);
    if (updatedDocument != null) {
      ref.read(selectedDocumentProvider.notifier).select(updatedDocument);
    } else {
      ref.read(selectedDocumentProvider.notifier).clear();
    }
    ref.read(selectedPageProvider.notifier).clear();
    clearDeleteHistory();
  }

  void deletePage(PdfPage page) {
    final flatPages = _flattenPages();
    final pageIndex = flatPages.indexWhere(
      (documentPage) => _isSamePage(documentPage, page),
    );
    if (pageIndex == -1) {
      return;
    }

    final deletedPage = flatPages[pageIndex];
    ref
        .read(lastDeletedPageActionProvider.notifier)
        .store(
          DeletedPageAction(
            lastDeletedPage: deletedPage,
            originalFlatPageIndex: pageIndex,
          ),
        );

    final nextPages = [...flatPages]..removeAt(pageIndex);
    state = _buildDocumentsFromPages(nextPages);

    if (nextPages.isEmpty) {
      ref.read(selectedDocumentProvider.notifier).clear();
    } else {
      final fallbackIndex = pageIndex >= nextPages.length
          ? nextPages.length - 1
          : pageIndex;
      final fallbackPage = nextPages[fallbackIndex];
      final updatedDocument = _findContainingDocument(fallbackPage);
      if (updatedDocument != null) {
        ref.read(selectedDocumentProvider.notifier).select(updatedDocument);
      } else {
        ref.read(selectedDocumentProvider.notifier).clear();
      }
    }

    ref.read(selectedPageProvider.notifier).clear();
  }

  void undoDelete() {
    final lastDeletedAction = ref.read(lastDeletedPageActionProvider);
    if (lastDeletedAction == null) {
      return;
    }

    final flatPages = _flattenPages();
    final restoredPages = [...flatPages];
    restoredPages.insert(
      _boundIndex(
        lastDeletedAction.originalFlatPageIndex,
        restoredPages.length,
      ),
      lastDeletedAction.lastDeletedPage,
    );

    state = _buildDocumentsFromPages(restoredPages);
    _selectPageAndContainingDocument(lastDeletedAction.lastDeletedPage);
    clearDeleteHistory();
  }

  void movePageUp(PdfPage page) {
    final flatPages = _flattenPages();
    final pageIndex = flatPages.indexWhere(
      (documentPage) => _isSamePage(documentPage, page),
    );
    if (pageIndex <= 0) {
      return;
    }

    final movedPages = [...flatPages];
    final currentPage = movedPages[pageIndex];
    movedPages[pageIndex] = movedPages[pageIndex - 1];
    movedPages[pageIndex - 1] = currentPage;

    state = _buildDocumentsFromPages(movedPages);
    _selectPageAndContainingDocument(page);
    clearDeleteHistory();
  }

  void movePageDown(PdfPage page) {
    final flatPages = _flattenPages();
    final pageIndex = flatPages.indexWhere(
      (documentPage) => _isSamePage(documentPage, page),
    );
    if (pageIndex == -1 || pageIndex >= flatPages.length - 1) {
      return;
    }

    final movedPages = [...flatPages];
    final currentPage = movedPages[pageIndex];
    movedPages[pageIndex] = movedPages[pageIndex + 1];
    movedPages[pageIndex + 1] = currentPage;

    state = _buildDocumentsFromPages(movedPages);
    _selectPageAndContainingDocument(page);
    clearDeleteHistory();
  }

  void clearDeleteHistory() {
    ref.read(lastDeletedPageActionProvider.notifier).clear();
  }

  void clearAll() {
    state = const [];
    ref.read(selectedPageProvider.notifier).clear();
    ref.read(selectedDocumentProvider.notifier).clear();
    clearDeleteHistory();
  }

  PdfSourceDocument? _findMatchingDocument(PdfSourceDocument targetDocument) {
    for (final document in state) {
      if (_isSameDocument(document, targetDocument)) {
        return document;
      }
    }
    return null;
  }

  PdfSourceDocument? _findContainingDocument(PdfPage targetPage) {
    for (final document in state) {
      for (final page in document.pages) {
        if (_isSamePage(page, targetPage)) {
          return document;
        }
      }
    }
    return null;
  }

  PdfPage? _findPage(PdfSourceDocument document, PdfPage targetPage) {
    for (final page in document.pages) {
      if (_isSamePage(page, targetPage)) {
        return page;
      }
    }
    return null;
  }

  List<PdfPage> _flattenPages([List<PdfSourceDocument>? documents]) {
    return [for (final document in documents ?? state) ...document.pages];
  }

  List<PdfSourceDocument> _buildDocumentsFromPages(List<PdfPage> pages) {
    if (pages.isEmpty) {
      return const [];
    }

    final nextDocuments = <PdfSourceDocument>[];
    final currentPages = <PdfPage>[];
    var currentPath = pages.first.sourceFilePath;

    void pushCurrentDocument() {
      if (currentPages.isEmpty) {
        return;
      }

      nextDocuments.add(
        PdfSourceDocument(
          sourceFilePath: currentPath,
          pages: List.unmodifiable([...currentPages]),
        ),
      );
      currentPages.clear();
    }

    for (final page in pages) {
      if (page.sourceFilePath != currentPath) {
        pushCurrentDocument();
        currentPath = page.sourceFilePath;
      }
      currentPages.add(page);
    }

    pushCurrentDocument();
    return List.unmodifiable(nextDocuments);
  }

  void _selectPageAndContainingDocument(PdfPage page) {
    final updatedDocument = _findContainingDocument(page);
    final updatedPage = updatedDocument == null
        ? null
        : _findPage(updatedDocument, page);

    if (updatedDocument != null) {
      ref.read(selectedDocumentProvider.notifier).select(updatedDocument);
    } else {
      ref.read(selectedDocumentProvider.notifier).clear();
    }

    if (updatedPage != null) {
      ref.read(selectedPageProvider.notifier).select(updatedPage);
    } else {
      ref.read(selectedPageProvider.notifier).clear();
    }
  }

  bool _isSamePage(PdfPage left, PdfPage right) {
    return left.sourceFilePath == right.sourceFilePath &&
        left.pageIndex == right.pageIndex;
  }

  bool _isSameDocument(PdfSourceDocument left, PdfSourceDocument right) {
    if (left.sourceFilePath != right.sourceFilePath ||
        left.pages.length != right.pages.length) {
      return false;
    }

    for (var index = 0; index < left.pages.length; index++) {
      if (!_isSamePage(left.pages[index], right.pages[index])) {
        return false;
      }
    }

    return true;
  }

  int _boundIndex(int index, int length) {
    if (index < 0) {
      return 0;
    }
    if (index > length) {
      return length;
    }
    return index;
  }

  int _nextRotation(int currentRotation, int degrees) {
    final normalizedDegrees = degrees % 360;
    final next = (currentRotation + normalizedDegrees) % 360;
    return next < 0 ? next + 360 : next;
  }
}
