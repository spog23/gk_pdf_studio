import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers/pdf_files_provider.dart';
import '../../models/pdf_page.dart';
import '../../models/pdf_source_document.dart';

class PdfFileSidebar extends ConsumerStatefulWidget {
  const PdfFileSidebar({super.key});

  @override
  ConsumerState<PdfFileSidebar> createState() => _PdfFileSidebarState();
}

class _PdfFileSidebarState extends ConsumerState<PdfFileSidebar> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                        controller: _scrollController,
                        thumbVisibility: true,
                        child: ReorderableListView.builder(
                          scrollController: _scrollController,
                          padding: const EdgeInsets.all(12),
                          primary: false,
                          physics: const BouncingScrollPhysics(),
                          buildDefaultDragHandles: false,
                          itemCount: pageEntries.length,
                          onReorder: (oldIndex, newIndex) {
                            var targetIndex = newIndex;
                            if (targetIndex > oldIndex) {
                              targetIndex -= 1;
                            }

                            ref
                                .read(pdfDocumentsProvider.notifier)
                                .reorderPage(oldIndex, targetIndex);
                          },
                          itemBuilder: (context, index) {
                            final entry = pageEntries[index];

                            return Padding(
                              key: ValueKey(_pageKey(entry.page)),
                              padding: EdgeInsets.only(
                                bottom: index == pageEntries.length - 1 ? 0 : 6,
                              ),
                              child: _PageRow(
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
                              ),
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

  String _pageKey(PdfPage page) {
    return '${page.sourceFilePath}::${page.pageIndex}';
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
    final rotationIndicator = _rotationIndicator(page.rotation);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF173041)
                  : const Color(0xFF141920),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF2E6D8D)
                    : const Color(0xFF1C242D),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(
                            text: '${orderIndex + 1}. ',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: 'Page ${page.pageIndex + 1} — $fileName',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ReorderableDragStartListener(
                    index: orderIndex,
                    child: Icon(
                      Icons.drag_handle,
                      size: 18,
                      color: isSelected ? Colors.white70 : Colors.white54,
                    ),
                  ),
                  if (rotationIndicator != null) ...[
                    const SizedBox(width: 12),
                    Text(
                      rotationIndicator,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _rotationIndicator(int rotation) {
    const clockwise = '\u{1F501}';

    switch (rotation % 360) {
      case 90:
        return clockwise;
      case 180:
        return '$clockwise$clockwise';
      case 270:
        return '$clockwise$clockwise$clockwise';
      default:
        return null;
    }
  }
}
