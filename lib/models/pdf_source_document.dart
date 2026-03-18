import 'pdf_page.dart';

class PdfSourceDocument {
  const PdfSourceDocument({
    required this.pages,
    required this.sourceFilePath,
  });

  final List<PdfPage> pages;
  final String sourceFilePath;

  PdfSourceDocument copyWith({
    List<PdfPage>? pages,
    String? sourceFilePath,
  }) {
    return PdfSourceDocument(
      pages: pages ?? this.pages,
      sourceFilePath: sourceFilePath ?? this.sourceFilePath,
    );
  }
}
