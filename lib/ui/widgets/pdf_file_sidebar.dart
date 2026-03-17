import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers/pdf_files_provider.dart';

class PdfFileSidebar extends ConsumerWidget {
  const PdfFileSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(pdfFilesProvider);

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
              files.isEmpty
                  ? 'Import one or more PDF files to populate this list.'
                  : '${files.length} file${files.length == 1 ? '' : 's'} loaded',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF222A33)),
                ),
                child: files.isEmpty
                    ? const Center(
                        child: Text('No PDFs imported yet.'),
                      )
                    : Scrollbar(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: files.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final file = files[index];

                            return DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F1318),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF26303B)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  file.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
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
}
