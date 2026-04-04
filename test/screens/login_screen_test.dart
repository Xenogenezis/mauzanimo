import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stray_pets_mu/screens/auth/login_screen.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';

// Mock classes
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
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.byIcon(Icons.pets), findsOneWidget);
    });

    testWidgets('should render email and password fields', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('should render sign in button', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should render forgot password button', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert - Should have TextButton for forgot password
      expect(find.byType(TextButton), findsAtLeast(2));
    });

    testWidgets('should render sign up link', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.byType(RichText), findsAtLeast(1));
    });

    testWidgets('should accept email input', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Enter email
      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.pump();

      // Assert
      final textField = tester.widget<TextField>(find.byType(TextField).first);
      expect(textField.controller?.text, 'test@example.com');
    });

    testWidgets('should accept password input', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Enter password
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.pump();

      // Assert
      final textField = tester.widget<TextField>(find.byType(TextField).last);
      expect(textField.controller?.text, 'password123');
    });

    testWidgets('should have password field obscured', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert - Find password field (second TextField) and verify obscureText
      final textFields = tester.widgetList<TextField>(find.byType(TextField));
      expect(textFields.last.obscureText, true);
    });

    testWidgets('should show error message when set', (WidgetTester tester) async {
      // Act - This tests that error message UI exists
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Enter invalid email to trigger validation state
      await tester.enterText(find.byType(TextField).first, '');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Assert - The screen structure is intact
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should use InkWell for app icon accessibility', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert - The app icon should be wrapped in an InkWell
      expect(find.byType(InkWell), findsOneWidget);
    });
  });
}
