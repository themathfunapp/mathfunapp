import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mathfun/providers/locale_provider.dart';

/// Tam uygulama [MyApp] Firebase + çoklu provider gerektirir; birim testinde
/// [LocaleProvider] davranışını doğrulamak terminalde `flutter test` için yeterli ve kararlıdır.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'user_language': 'tr'});
  });

  testWidgets('LocaleProvider kayıtlı dili yükler', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<LocaleProvider>(
        create: (_) => LocaleProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: Consumer<LocaleProvider>(
              builder: (context, loc, _) {
                if (loc.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Text('dil:${loc.locale.languageCode}');
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('dil:tr'), findsOneWidget);
  });
}
