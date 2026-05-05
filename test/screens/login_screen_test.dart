import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stray_pets_mu/screens/auth/login_screen.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';

class MockLanguageProvider extends Mock implements LanguageProvider {}

void main() {
  late MockLanguageProvider mockLanguageProvider;

  setUp(() {
    mockLanguageProvider = MockLanguageProvider();
    when(() => mockLanguageProvider.lang).thenReturn('en');
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: ChangeNotifierProvider<LanguageProvider>.value(
        value: mockLanguageProvider,
        child: const LoginScreen(),
      ),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('should render app icon', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.pets), findsOneWidget);
    });

    testWidgets('should render email and password fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('should render sign in button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should render forgot password button',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(TextButton), findsAtLeast(2));
    });

    testWidgets('should render sign up link', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(RichText), findsAtLeast(1));
    });

    testWidgets('should accept email input', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.pump();

      final textField =
          tester.widget<TextField>(find.byType(TextField).first);
      expect(textField.controller?.text, 'test@example.com');
    });

    testWidgets('should accept password input', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.pump();

      final textField =
          tester.widget<TextField>(find.byType(TextField).last);
      expect(textField.controller?.text, 'password123');
    });

    testWidgets('should have password field obscured',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      final textFields =
          tester.widgetList<TextField>(find.byType(TextField));
      expect(textFields.last.obscureText, true);
    });

    testWidgets('should have tappable icon for admin access',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // The icon is wrapped in GestureDetector for the admin easter egg
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('should have scaffold', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
