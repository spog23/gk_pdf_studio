import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers/pdf_files_provider.dart';
import 'pdf_file_sidebar.dart';
import 'pdf_preview_widget.dart';

class EditorWorkspace extends StatelessWidget {
  const EditorWorkspace({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 960;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: isCompact
              ? const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: PdfFileSidebar()),
                    SizedBox(height: 16),
                    Expanded(child: _EditorPreviewPanel()),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(width: 320, child: PdfFileSidebar()),
                    const SizedBox(width: 16),
                    const Expanded(child: _EditorPreviewPanel()),
                  ],
                ),
        );
      },
    );
  }
}

class _EditorPreviewPanel extends ConsumerWidget {
  const _EditorPreviewPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPage = ref.watch(selectedPageProvider);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF111418),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1D232B)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Page Preview',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              selectedPage == null
                  ? 'Select a page from the sidebar to preview it here.'
                  : 'Showing page ${selectedPage.pageIndex + 1} from the selected PDF.',
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF222A33)),
                ),
                child: selectedPage == null
                    ? const Center(
                        child: Text(
                          'Select a page to preview.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : PdfPreviewWidget(page: selectedPage),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
