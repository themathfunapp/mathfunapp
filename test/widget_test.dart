import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mathfunapp/main.dart';

void main() {
  testWidgets('Matematik Macerası başlık testi', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MathFunApp());

    // Verify that our app title is correct
    expect(find.text('Matematik Macerası'), findsOneWidget);

    // Veya HomeScreen'deki bir elementi kontrol edebiliriz
    expect(find.text('Eğlenerek Öğren'), findsOneWidget);
  });
}