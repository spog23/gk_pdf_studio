import 'package:file_picker/file_picker.dart';

import '../models/pdf_file.dart';

class PdfFileImportService {
  Future<List<PdfFile>> pickPdfFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      dialogTitle: 'Import PDF files',
    );

    if (result == null) {
      return const [];
    }

    return result.files
        .where((file) => file.path != null)
        .where((file) => file.extension?.toLowerCase() == 'pdf')
        .map(
          (file) => PdfFile(
            name: file.name,
            path: file.path!,
          ),
        )
        .toList(growable: false);
  }
}
