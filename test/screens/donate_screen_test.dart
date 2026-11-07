import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/screens/info/donate_screen.dart';
import 'package:stray_pets_mu/utils/app_contact.dart';

class MockLanguageProvider extends Mock implements LanguageProvider {}

void main() {
  testWidgets('bank section is hidden while no donation account is set',
      (tester) async {
    final lang = MockLanguageProvider();
    when(() => lang.lang).thenReturn('en');
    await tester.pumpWidget(ChangeNotifierProvider<LanguageProvider>.value(
      value: lang,
      child: const MaterialApp(home: DonateScreen()),
    ));
    expect(kDonationBankDetails, isEmpty);
    expect(find.byType(CopyableDetail), findsNothing);
    expect(find.text('Bank Transfer Details'), findsNothing);
    expect(find.textContaining('JCI'), findsNothing);
  });

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
      child: const MaterialApp(
        home: Scaffold(
          body: CopyableDetail(text: 'Account No: 1234-5678', lang: 'en'),
        ),
      ),
    ));

    await tester.tap(find.text('Account No: 1234-5678'));
    await tester.pump();

    expect(copied, '1234-5678');
    expect(find.text('Copied'), findsOneWidget);
  });
}
