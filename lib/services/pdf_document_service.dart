import '../models/pdf_document.dart';

class PdfDocumentService {
  Future<PdfDocument?> restoreDraft() async {
    return null;
  }

  Future<PdfDocument> createDraft() async {
    return const PdfDocument(
      name: 'Untitled Document',
      pageCount: 0,
    );
  }
}
