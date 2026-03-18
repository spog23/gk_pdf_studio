class PdfPage {
  const PdfPage({
    required this.pageIndex,
    required this.sourceFilePath,
    this.rotation = 0,
  });

  final int pageIndex;
  final String sourceFilePath;
  final int rotation;

  PdfPage copyWith({
    int? pageIndex,
    String? sourceFilePath,
    int? rotation,
  }) {
    return PdfPage(
      pageIndex: pageIndex ?? this.pageIndex,
      sourceFilePath: sourceFilePath ?? this.sourceFilePath,
      rotation: rotation ?? this.rotation,
    );
  }
}
