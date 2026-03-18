import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gk_pdf_studio/controllers/providers/pdf_files_provider.dart';
import 'package:gk_pdf_studio/core/app.dart';
import 'package:gk_pdf_studio/core/theme/app_theme.dart';
import 'package:gk_pdf_studio/models/pdf_page.dart';
import 'package:gk_pdf_studio/models/pdf_source_document.dart';
import 'package:gk_pdf_studio/ui/screens/home_screen.dart';

void main() {
  PdfSourceDocument createDocument(String path, int pageCount) {
    return PdfSourceDocument(
      sourceFilePath: path,
      pages: List.generate(
        pageCount,
        (index) => PdfPage(pageIndex: index, sourceFilePath: path),
      ),
    );
  }

  TextButton findButton(WidgetTester tester, String label) {
    return tester.widget<TextButton>(find.widgetWithText(TextButton, label));
  }

  Future<void> pumpWideApp(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(child);
    await tester.pump();
  }

  testWidgets('renders the updated PDF toolbar shell', (
    WidgetTester tester,
  ) async {
    await pumpWideApp(tester, const GKPdfStudioApp());

    expect(find.text('GK PDF Studio'), findsOneWidget);
    expect(find.text('Import PDF'), findsOneWidget);
    expect(find.text('Rotate'), findsOneWidget);
    expect(find.text('Delete Page'), findsOneWidget);
    expect(find.text('Move Up'), findsOneWidget);
    expect(find.text('Move Down'), findsOneWidget);
    expect(find.text('Export'), findsOneWidget);
    expect(find.text('Clear All'), findsOneWidget);
    expect(find.text('Imported PDFs'), findsOneWidget);
    expect(find.text('No PDFs imported yet.'), findsOneWidget);
  });

  testWidgets('toolbar buttons enable and disable based on page state', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await pumpWideApp(
      tester,
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.dark(), home: const HomeScreen()),
      ),
    );

    expect(findButton(tester, 'Rotate').onPressed, isNull);
    expect(findButton(tester, 'Delete Page').onPressed, isNull);
    expect(findButton(tester, 'Move Up').onPressed, isNull);
    expect(findButton(tester, 'Move Down').onPressed, isNull);
    expect(findButton(tester, 'Export').onPressed, isNull);
    expect(findButton(tester, 'Clear All').onPressed, isNull);

    final document = createDocument('file1.pdf', 2);
    container.read(pdfDocumentsProvider.notifier).addDocuments([document]);
    await tester.pump();

    expect(findButton(tester, 'Export').onPressed, isNotNull);
    expect(findButton(tester, 'Clear All').onPressed, isNotNull);
    expect(findButton(tester, 'Rotate').onPressed, isNull);

    final firstPage = container.read(pdfDocumentsProvider).first.pages.first;
    container.read(selectedPageProvider.notifier).select(firstPage);
    await tester.pump();

    expect(findButton(tester, 'Rotate').onPressed, isNotNull);
    expect(findButton(tester, 'Delete Page').onPressed, isNotNull);
    expect(findButton(tester, 'Move Up').onPressed, isNull);
    expect(findButton(tester, 'Move Down').onPressed, isNotNull);

    final lastPage = container.read(pdfDocumentsProvider).first.pages.last;
    container.read(selectedPageProvider.notifier).select(lastPage);
    await tester.pump();

    expect(findButton(tester, 'Move Up').onPressed, isNotNull);
    expect(findButton(tester, 'Move Down').onPressed, isNull);
  });
}
