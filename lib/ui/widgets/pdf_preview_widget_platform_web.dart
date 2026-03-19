import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../models/pdf_page.dart';

Widget buildPdfPreviewWidget({required PdfPage page}) {
  return _SyncfusionWebPreview(page: page);
}

class _SyncfusionWebPreview extends StatefulWidget {
  const _SyncfusionWebPreview({required this.page});

  final PdfPage page;

  @override
  State<_SyncfusionWebPreview> createState() => _SyncfusionWebPreviewState();
}

class _SyncfusionWebPreviewState extends State<_SyncfusionWebPreview> {
  final Map<String, Future<Uint8List>> _documentCache = {};
  late PdfViewerController _controller;
  late Future<Uint8List> _bytesFuture;
  late String _sourceFilePath;
  var _hasLoadError = false;
  var _isDocumentLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeViewer(widget.page);
  }

  @override
  void didUpdateWidget(covariant _SyncfusionWebPreview oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.page.sourceFilePath != widget.page.sourceFilePath) {
      _controller.dispose();
      _initializeViewer(widget.page);
      return;
    }

    if (oldWidget.page.pageIndex != widget.page.pageIndex &&
        _isDocumentLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.jumpToPage(widget.page.pageIndex + 1);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasLoadError) {
      return const _PreviewUnavailable();
    }

    return FutureBuilder<Uint8List>(
      future: _bytesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const _PreviewUnavailable();
        }

        return RotatedBox(
          quarterTurns: (widget.page.rotation ~/ 90) % 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SfPdfViewer.memory(
              snapshot.data!,
              key: ValueKey(_sourceFilePath),
              controller: _controller,
              initialPageNumber: widget.page.pageIndex + 1,
              pageLayoutMode: PdfPageLayoutMode.single,
              canShowScrollHead: false,
              canShowPaginationDialog: false,
              canShowScrollStatus: false,
              canShowHyperlinkDialog: false,
              enableDoubleTapZooming: false,
              enableHyperlinkNavigation: false,
              onDocumentLoaded: (_) {
                _isDocumentLoaded = true;
                _controller.jumpToPage(widget.page.pageIndex + 1);
              },
              onDocumentLoadFailed: (_) {
                if (mounted) {
                  setState(() {
                    _hasLoadError = true;
                  });
                }
              },
            ),
          ),
        );
      },
    );
  }

  void _initializeViewer(PdfPage page) {
    _controller = PdfViewerController();
    _sourceFilePath = page.sourceFilePath;
    _bytesFuture = _loadDocumentBytes(page.sourceFilePath);
    _hasLoadError = false;
    _isDocumentLoaded = false;
  }

  Future<Uint8List> _loadDocumentBytes(String sourceFilePath) {
    return _documentCache.putIfAbsent(sourceFilePath, () async {
      final uri = Uri.tryParse(sourceFilePath);
      if (uri != null && uri.hasScheme) {
        final bundle = NetworkAssetBundle(uri);
        final data = await bundle.load(uri.toString());
        return data.buffer.asUint8List();
      }

      final data = await rootBundle.load(sourceFilePath);
      return data.buffer.asUint8List();
    });
  }
}

class _PreviewUnavailable extends StatelessWidget {
  const _PreviewUnavailable();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Preview not available',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }
}
