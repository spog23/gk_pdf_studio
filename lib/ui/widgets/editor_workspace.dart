import 'package:flutter/material.dart';

import 'pdf_file_sidebar.dart';

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
                    Expanded(
                      child: PdfFileSidebar(),
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: _EditorPlaceholder(),
                    ),
                  ],
                )
              : Row(
                  children: [
                    const SizedBox(
                      width: 320,
                      child: PdfFileSidebar(),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: _EditorPlaceholder(),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _EditorPlaceholder extends StatelessWidget {
  const _EditorPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF111418),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1D232B)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Editor Workspace',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'PDF rendering is intentionally not implemented yet. '
              'Use the left sidebar to manage imported files.',
              style: TextStyle(
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
