import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers/merge_controller.dart';
import '../../models/pdf_page.dart';
import '../../controllers/providers/pdf_files_provider.dart';
import '../../models/pdf_source_document.dart';
import '../widgets/editor_workspace.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const String _undoDeleteSnackBarLabel = 'Page deleted';

  Future<void> _importPdfDocuments(BuildContext context, WidgetRef ref) async {
    try {
      final importService = ref.read(pdfImportServiceProvider);
      final documents = await importService.pickPdfDocuments();

      if (!context.mounted || documents.isEmpty) {
        return;
      }

      ref.read(pdfDocumentsProvider.notifier).addDocuments(documents);
      _showImportSummary(context, documents);
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to import PDF files.')),
      );
    }
  }

  void _showImportSummary(
    BuildContext context,
    List<PdfSourceDocument> documents,
  ) {
    final label = documents.length == 1
        ? '1 PDF imported'
        : '${documents.length} PDFs imported';

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(label)));
  }

  Future<String?> _pickExportOutputPath(
    List<PdfSourceDocument> documents,
  ) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final suggestedFileName = 'exported_$timestamp.pdf';
    final initialDirectory = documents.isEmpty
        ? null
        : File(documents.first.sourceFilePath).parent.path;

    return FilePicker.platform.saveFile(
      dialogTitle: 'Save exported PDF',
      fileName: suggestedFileName,
      initialDirectory: initialDirectory,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      lockParentWindow: true,
    );
  }

  Future<void> _exportPdf(BuildContext context, WidgetRef ref) async {
    final documents = ref.read(pdfDocumentsProvider);

    if (documents.isEmpty) {
      return;
    }

    try {
      final outputPath = await _pickExportOutputPath(documents);

      if (!context.mounted) {
        return;
      }

      if (outputPath == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Save cancelled')));
        return;
      }

      final outputFile = await ref
          .read(mergeControllerProvider.notifier)
          .mergeFiles(documents, outputPath);

      if (!context.mounted) {
        return;
      }

      ref.read(pdfDocumentsProvider.notifier).clearDeleteHistory();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File saved to: ${outputFile.path}')),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to export PDF file.')),
      );
    }
  }

  void _deleteSelectedPage(BuildContext context, WidgetRef ref) {
    final selectedPage = ref.read(selectedPageProvider);
    if (selectedPage == null) {
      return;
    }

    ref.read(pdfDocumentsProvider.notifier).deletePage(selectedPage);
    if (ref.read(lastDeletedPageActionProvider) == null) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: const Text(_undoDeleteSnackBarLabel),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            if (ref.read(lastDeletedPageActionProvider) == null) {
              messenger.hideCurrentSnackBar();
              return;
            }

            ref.read(pdfDocumentsProvider.notifier).undoDelete();
            messenger.hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _rotateSelection(WidgetRef ref) {
    final selectedPage = ref.read(selectedPageProvider);

    if (selectedPage != null) {
      ref.read(pdfDocumentsProvider.notifier).rotatePage(selectedPage, 90);
    }
  }

  void _moveSelectedPageUp(WidgetRef ref) {
    final selectedPage = ref.read(selectedPageProvider);
    if (selectedPage != null) {
      ref.read(pdfDocumentsProvider.notifier).movePageUp(selectedPage);
    }
  }

  void _moveSelectedPageDown(WidgetRef ref) {
    final selectedPage = ref.read(selectedPageProvider);
    if (selectedPage != null) {
      ref.read(pdfDocumentsProvider.notifier).movePageDown(selectedPage);
    }
  }

  int _selectedPageFlatIndex(
    List<PdfSourceDocument> documents,
    PdfPage? selectedPage,
  ) {
    if (selectedPage == null) {
      return -1;
    }

    var index = 0;
    for (final document in documents) {
      for (final page in document.pages) {
        if (page.sourceFilePath == selectedPage.sourceFilePath &&
            page.pageIndex == selectedPage.pageIndex) {
          return index;
        }
        index++;
      }
    }

    return -1;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<DeletedPageAction?>(lastDeletedPageActionProvider, (
      previous,
      next,
    ) {
      if (previous != null && next == null && context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    });

    final importedDocuments = ref.watch(pdfDocumentsProvider);
    final mergeState = ref.watch(mergeControllerProvider);
    final selectedPage = ref.watch(selectedPageProvider);
    final isMerging = mergeState.isLoading;
    final totalPages = importedDocuments.fold<int>(
      0,
      (count, document) => count + document.pages.length,
    );
    final selectedPageIndex = _selectedPageFlatIndex(
      importedDocuments,
      selectedPage,
    );
    final canDelete = !isMerging && selectedPage != null;
    final canRotate = !isMerging && selectedPage != null;
    final canMoveUp = !isMerging && selectedPageIndex > 0;
    final canMoveDown =
        !isMerging &&
        selectedPageIndex != -1 &&
        selectedPageIndex < totalPages - 1;
    final canExport = !isMerging && totalPages > 0;
    final canClearAll = !isMerging && importedDocuments.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('GK PDF Studio')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: _ToolbarCard(
              leftButtons: [
                TextButton(
                  onPressed: isMerging
                      ? null
                      : () => _importPdfDocuments(context, ref),
                  child: const Text('Import PDF'),
                ),
              ],
              centerButtons: [
                TextButton(
                  onPressed: canRotate ? () => _rotateSelection(ref) : null,
                  child: const Text('Rotate'),
                ),
                TextButton(
                  onPressed: canDelete
                      ? () => _deleteSelectedPage(context, ref)
                      : null,
                  child: const Text('Delete Page'),
                ),
                TextButton(
                  onPressed: canMoveUp ? () => _moveSelectedPageUp(ref) : null,
                  child: const Text('Move Up'),
                ),
                TextButton(
                  onPressed: canMoveDown
                      ? () => _moveSelectedPageDown(ref)
                      : null,
                  child: const Text('Move Down'),
                ),
              ],
              rightButtons: [
                TextButton(
                  onPressed: canExport ? () => _exportPdf(context, ref) : null,
                  child: Text(isMerging ? 'Exporting...' : 'Export'),
                ),
                TextButton(
                  onPressed: canClearAll
                      ? () {
                          ref.read(pdfDocumentsProvider.notifier).clearAll();
                        }
                      : null,
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),
          const Expanded(child: EditorWorkspace()),
        ],
      ),
    );
  }
}

class _ToolbarCard extends StatelessWidget {
  const _ToolbarCard({
    required this.leftButtons,
    required this.centerButtons,
    required this.rightButtons,
  });

  final List<Widget> leftButtons;
  final List<Widget> centerButtons;
  final List<Widget> rightButtons;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF111418),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1D232B)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 900) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: leftButtons,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: centerButtons,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: rightButtons,
                    ),
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: leftButtons,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: centerButtons,
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: rightButtons,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
