import 'package:flutter/material.dart';

import '../../models/pdf_page.dart';

Widget buildPdfPreviewWidget({required PdfPage page}) {
  return const _PreviewUnavailable();
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
