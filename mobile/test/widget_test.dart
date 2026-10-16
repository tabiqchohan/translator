import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:translater/widgets/language_selector.dart';

void main() {
  testWidgets('LanguageSelector shows selected language', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LanguageSelector(selectedCode: 'en', onChanged: (_) {}),
        ),
      ),
    );

    expect(find.text('English'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
  });

  testWidgets('LanguageSelector opens searchable picker and selects a language',
      (tester) async {
    String? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LanguageSelector(
            selectedCode: 'en',
            onChanged: (val) => selected = val,
          ),
        ),
      ),
    );

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Select Language'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'urdu');
    await tester.pumpAndSettle();

    expect(find.text('Urdu'), findsOneWidget);
    expect(find.text('French'), findsNothing);

    await tester.tap(find.text('Urdu'));
    await tester.pumpAndSettle();

    expect(selected, 'ur');
  });
}
