import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers/pdf_files_provider.dart';
import '../../models/pdf_page.dart';
import '../../models/pdf_source_document.dart';
import 'pdf_preview_widget_platform_stub.dart'
    if (dart.library.io) 'pdf_preview_widget_platform_io.dart'
    if (dart.library.js_interop) 'pdf_preview_widget_platform_web.dart'
    as platform_preview;

class PdfPreviewWidget extends ConsumerWidget {
  const PdfPreviewWidget({required this.page, super.key});

  final PdfPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = ref.watch(pdfDocumentsProvider);
    final outputIndex = _findOutputIndex(documents, page);

    if (_usesFallbackPreview()) {
      return _FallbackPreview(outputIndex: outputIndex, page: page);
    }

    return platform_preview.buildPdfPreviewWidget(page: page);
  }

  bool _usesFallbackPreview() {
    if (kIsWeb) {
      return false;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => false,
      _ => true,
    };
  }

  int _findOutputIndex(
    List<PdfSourceDocument> documents,
    PdfPage selectedPage,
  ) {
    var index = 0;
    for (final document in documents) {
      for (final documentPage in document.pages) {
        if (documentPage.sourceFilePath == selectedPage.sourceFilePath &&
            documentPage.pageIndex == selectedPage.pageIndex) {
          return index;
        }
        index++;
      }
    }

    return -1;
  }
}

class _FallbackPreview extends StatelessWidget {
  const _FallbackPreview({required this.outputIndex, required this.page});

  static const double _a4AspectRatio = 1 / 1.4142;

  final int outputIndex;
  final PdfPage page;

  @override
  Widget build(BuildContext context) {
    final fileName = _fileNameFromPath(page.sourceFilePath);
    final rotationLabel = page.rotation == 0 ? null : '↻ ${page.rotation}°';

    return LayoutBuilder(
      builder: (context, constraints) {
        const metadataHeight = 88.0;
        final availableHeight = math.max(
          220.0,
          constraints.maxHeight - metadataHeight - 40,
        );
        final pageWidth = math.min(
          constraints.maxWidth * 0.62,
          availableHeight * _a4AspectRatio,
        );
        final pageHeight = pageWidth / _a4AspectRatio;

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: pageWidth,
                  height: pageHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F1EA),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 26,
                          offset: Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 32,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            outputIndex == -1
                                ? 'Page ?'
                                : 'Page ${outputIndex + 1}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: const Color(0xFF1E252D),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          if (rotationLabel != null) ...[
                            const SizedBox(height: 18),
                            Text(
                              rotationLabel,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: const Color(0xFF56616C),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Source: Page ${page.pageIndex + 1} — $fileName',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rotation: ${page.rotation}°',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _fileNameFromPath(String path) {
    final segments = path.split(RegExp(r'[\\/]'));
    return segments.isEmpty ? path : segments.last;
  }
}
