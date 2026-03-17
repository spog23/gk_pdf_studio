import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers/merge_controller.dart';
import '../../controllers/providers/pdf_files_provider.dart';
import '../../models/pdf_file.dart';
import '../widgets/editor_workspace.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _importPdfFiles(BuildContext context, WidgetRef ref) async {
    try {
      final importService = ref.read(pdfFileImportServiceProvider);
      final files = await importService.pickPdfFiles();

      if (!context.mounted || files.isEmpty) {
        return;
      }

      ref.read(pdfFilesProvider.notifier).addFiles(files);
      _showImportSummary(context, files);
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to import PDF files.'),
        ),
      );
    }
  }

  void _showImportSummary(BuildContext context, List<PdfFile> files) {
    final label =
        files.length == 1 ? '1 PDF imported' : '${files.length} PDFs imported';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(label)),
    );
  }

  Future<String?> _pickMergeOutputPath(List<PdfFile> files) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final suggestedFileName = 'merged_$timestamp.pdf';
    final initialDirectory = files.isEmpty
        ? null
        : File(files.first.path).parent.path;

    return FilePicker.platform.saveFile(
      dialogTitle: 'Save merged PDF',
      fileName: suggestedFileName,
      initialDirectory: initialDirectory,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      lockParentWindow: true,
    );
  }

  Future<void> _mergeAndExport(BuildContext context, WidgetRef ref) async {
    final files = ref.read(pdfFilesProvider);

    if (files.isEmpty) {
      return;
    }

    try {
      final outputPath = await _pickMergeOutputPath(files);

      if (!context.mounted) {
        return;
      }

      if (outputPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Save cancelled'),
          ),
        );
        return;
      }

      final outputFile = await ref
          .read(mergeControllerProvider.notifier)
          .mergeFiles(files, outputPath);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File saved to: ${outputFile.path}'),
        ),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to merge PDF files.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final importedFiles = ref.watch(pdfFilesProvider);
    final mergeState = ref.watch(mergeControllerProvider);
    final isMerging = mergeState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GK PDF Studio'),
        actions: [
          TextButton(
            onPressed: isMerging ? null : () => _importPdfFiles(context, ref),
            child: const Text('Import PDF'),
          ),
          TextButton(
            onPressed: importedFiles.isEmpty || isMerging
                ? null
                : () => _mergeAndExport(context, ref),
            child: Text(isMerging ? 'Merging...' : 'Merge & Export'),
          ),
          if (importedFiles.isNotEmpty)
            TextButton(
              onPressed: isMerging
                  ? null
                  : () {
                ref.read(pdfFilesProvider.notifier).clearAll();
              },
              child: const Text('Clear All'),
            ),
          const SizedBox(width: 12),
        ],
      ),
      body: const EditorWorkspace(),
    );
  }
}
