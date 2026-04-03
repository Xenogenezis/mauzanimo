import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stray_pets_mu/screens/pets/pet_list_screen.dart';
import 'package:stray_pets_mu/lang/language_provider.dart';

// Mock classes
class MockLanguageProvider extends Mock implements LanguageProvider {}

class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

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
        child: const Scaffold(
          body: PetListScreen(),
        ),
      ),
    );
  }

  group('PetListScreen Widget Tests', () {
    testWidgets('should render search bar', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('should render filter chips', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Dogs'), findsOneWidget);
      expect(find.text('Cats'), findsOneWidget);
      expect(find.text('Others'), findsOneWidget);
    });

    testWidgets('should render filter list horizontally', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should show loading indicator initially', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert - Shows CircularProgressIndicator while waiting for stream
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should update search query on text input', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Enter search text
      await tester.enterText(find.byType(TextField), 'Buddy');
      await tester.pump();

      // Assert - Text field contains the input
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, 'Buddy');
    });

    testWidgets('should have ChoiceChip widgets', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Assert
      expect(find.byType(ChoiceChip), findsAtLeast(4));
    });
  });
}
