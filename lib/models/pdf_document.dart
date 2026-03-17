class PdfDocument {
  const PdfDocument({
    required this.name,
    required this.pageCount,
    this.path,
    this.isDirty = false,
  });

  final String name;
  final int pageCount;
  final String? path;
  final bool isDirty;

  PdfDocument copyWith({
    String? name,
    int? pageCount,
    String? path,
    bool? isDirty,
  }) {
    return PdfDocument(
      name: name ?? this.name,
      pageCount: pageCount ?? this.pageCount,
      path: path ?? this.path,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}
