import 'package:flutter/foundation.dart';

import '../models/pdf_source_document.dart';
import '../services/pdf_document_service.dart';

class PdfEditorController extends ChangeNotifier {
  PdfEditorController({PdfDocumentService? documentService})
      : _documentService = documentService ?? PdfDocumentService();

  final PdfDocumentService _documentService;

  PdfSourceDocument? _activeDocument;
  bool _isLoading = false;
  bool _isInitialized = false;

  PdfSourceDocument? get activeDocument => _activeDocument;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    _isInitialized = true;
    _isLoading = true;
    notifyListeners();

    final restoredDocument = await _documentService.restoreDraft();
    _activeDocument = restoredDocument ?? await _documentService.createDraft();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createNewDocument() async {
    _isLoading = true;
    notifyListeners();

    _activeDocument = await _documentService.createDraft();

    _isLoading = false;
    notifyListeners();
  }
}
