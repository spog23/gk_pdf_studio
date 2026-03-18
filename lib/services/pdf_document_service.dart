import '../models/pdf_source_document.dart';

class PdfDocumentService {
  Future<PdfSourceDocument?> restoreDraft() async {
    return null;
  }

  Future<PdfSourceDocument> createDraft() async {
    return const PdfSourceDocument(
      pages: [],
      sourceFilePath: '',
    );
  }
}
