import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers/pdf_files_provider.dart';
import '../../models/pdf_page.dart';
import '../../models/pdf_source_document.dart';

class PdfFileSidebar extends ConsumerWidget {
  const PdfFileSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = ref.watch(pdfDocumentsProvider);
    final selectedPage = ref.watch(selectedPageProvider);
    final pageEntries = _buildPageEntries(documents);
    final uniqueFileCount = documents
        .map((document) => document.sourceFilePath)
        .toSet()
        .length;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF111418),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1D232B)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Imported PDFs',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              pageEntries.isEmpty
                  ? 'Import one or more PDF files to populate this list.'
                  : '${pageEntries.length} page${pageEntries.length == 1 ? '' : 's'} from '
                        '$uniqueFileCount file${uniqueFileCount == 1 ? '' : 's'}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF222A33)),
                ),
                child: pageEntries.isEmpty
                    ? const Center(child: Text('No PDFs imported yet.'))
                    : Scrollbar(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: pageEntries.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final entry = pageEntries[index];

                            return _PageRow(
                              orderIndex: index,
                              page: entry.page,
                              fileName: _fileNameFromPath(
                                entry.page.sourceFilePath,
                              ),
                              isSelected: _isSelectedPage(
                                entry.page,
                                selectedPage,
                              ),
                              onTap: () {
                                ref
                                    .read(selectedDocumentProvider.notifier)
                                    .select(entry.document);
                                ref
                                    .read(selectedPageProvider.notifier)
                                    .select(entry.page);
                              },
                            );
                          },
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_PageEntry> _buildPageEntries(List<PdfSourceDocument> documents) {
    return [
      for (final document in documents)
        for (final page in document.pages)
          _PageEntry(document: document, page: page),
    ];
  }

  bool _isSelectedPage(PdfPage page, PdfPage? selectedPage) {
    return selectedPage != null &&
        selectedPage.sourceFilePath == page.sourceFilePath &&
        selectedPage.pageIndex == page.pageIndex;
  }

  String _fileNameFromPath(String path) {
    final segments = path.split(RegExp(r'[\\/]'));
    return segments.isEmpty ? path : segments.last;
  }
}

class _PageEntry {
  const _PageEntry({required this.document, required this.page});

  final PdfSourceDocument document;
  final PdfPage page;
}

class _PageRow extends StatelessWidget {
  const _PageRow({
    required this.orderIndex,
    required this.page,
    required this.fileName,
    required this.isSelected,
    required this.onTap,
  });

  final int orderIndex;
  final PdfPage page;
  final String fileName;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFF173041) : const Color(0xFF141920),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF22516A)
                      : const Color(0xFF1B232D),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${orderIndex + 1}'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Page ${page.pageIndex + 1} ($fileName)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (page.rotation != 0)
                Text(
                  '${page.rotation} deg',
                  style: const TextStyle(color: Colors.white70),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
