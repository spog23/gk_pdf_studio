import 'package:flutter_test/flutter_test.dart';

import 'package:gk_pdf_studio/core/app.dart';

void main() {
  testWidgets('renders the PDF import shell', (WidgetTester tester) async {
    await tester.pumpWidget(const GKPdfStudioApp());
    await tester.pump();

    expect(find.text('GK PDF Studio'), findsOneWidget);
    expect(find.text('Import PDF'), findsOneWidget);
    expect(find.text('Merge & Export'), findsOneWidget);
    expect(find.text('Imported PDFs'), findsOneWidget);
    expect(find.text('No PDFs imported yet.'), findsOneWidget);
  });
}
