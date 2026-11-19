import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quiz_bilingual/presentation/widgets/option_tile.dart';

void main() {
  testWidgets('OptionTile meets Android minimum 48x48 tap target guideline',
      (WidgetTester tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: OptionTile(
              label: 'A',
              text: 'Khai báo hằng số const trong Dart',
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    // Verify tap target accessibility guideline (Question 175 in Course Syllabus)
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    handle.dispose();
  });
}
