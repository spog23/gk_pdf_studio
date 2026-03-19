import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../models/pdf_page.dart';

Widget buildPdfPreviewWidget({required PdfPage page}) {
  return _SyncfusionFilePreview(page: page);
}

class _SyncfusionFilePreview extends StatefulWidget {
  const _SyncfusionFilePreview({required this.page});

  final PdfPage page;

  @override
  State<_SyncfusionFilePreview> createState() => _SyncfusionFilePreviewState();
}

class _SyncfusionFilePreviewState extends State<_SyncfusionFilePreview> {
  late PdfViewerController _controller;
  late String _sourceFilePath;
  var _hasLoadError = false;
  var _isDocumentLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeViewer(widget.page);
  }

  @override
  void didUpdateWidget(covariant _SyncfusionFilePreview oldWidget) {
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

    return RotatedBox(
      quarterTurns: (widget.page.rotation ~/ 90) % 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SfPdfViewer.file(
          File(_sourceFilePath),
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
  }

  void _initializeViewer(PdfPage page) {
    _controller = PdfViewerController();
    _sourceFilePath = page.sourceFilePath;
    _hasLoadError = false;
    _isDocumentLoaded = false;
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
