import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/screens/info/donate_screen.dart';

class MockLanguageProvider extends Mock implements LanguageProvider {}

void main() {
  testWidgets('tapping a payment detail copies its value', (tester) async {
    final lang = MockLanguageProvider();
    when(() => lang.lang).thenReturn('en');

    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );

    await tester.pumpWidget(ChangeNotifierProvider<LanguageProvider>.value(
      value: lang,
      child: const MaterialApp(home: DonateScreen()),
    ));

    expect(find.byType(CopyableDetail), findsNWidgets(4));
    final account = find.text('Account No: XXXX-XXXX-XXXX');
    await tester.ensureVisible(account);
    await tester.tap(account);
    await tester.pump();

    expect(copied, 'XXXX-XXXX-XXXX');
    expect(find.text('Copied'), findsOneWidget);
  });
}
