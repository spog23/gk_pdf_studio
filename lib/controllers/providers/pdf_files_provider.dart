import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/pdf_file.dart';
import '../../services/pdf_file_import_service.dart';

final pdfFileImportServiceProvider = Provider<PdfFileImportService>((ref) {
  return PdfFileImportService();
});

final pdfFilesProvider =
    NotifierProvider<PdfFilesNotifier, List<PdfFile>>(PdfFilesNotifier.new);

class PdfFilesNotifier extends Notifier<List<PdfFile>> {
  @override
  List<PdfFile> build() {
    return const [];
  }

  void addFiles(List<PdfFile> files) {
    if (files.isEmpty) {
      return;
    }

    final nextFiles = [...state];

    for (final file in files) {
      final alreadyExists = nextFiles.any(
        (existingFile) => existingFile.path == file.path,
      );

      if (!alreadyExists) {
        nextFiles.add(file);
      }
    }

    state = List.unmodifiable(nextFiles);
  }

  void clearAll() {
    state = const [];
  }
}
