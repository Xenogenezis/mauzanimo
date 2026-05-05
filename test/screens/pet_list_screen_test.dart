import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stray_pets_mu/screens/pets/pet_list_screen.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/providers/pet_provider.dart';

class MockLanguageProvider extends Mock implements LanguageProvider {}

class MockPetProvider extends Mock implements PetProvider {}

void main() {
  late MockLanguageProvider mockLanguageProvider;
  late MockPetProvider mockPetProvider;

  setUp(() {
    mockLanguageProvider = MockLanguageProvider();
    when(() => mockLanguageProvider.lang).thenReturn('en');

    mockPetProvider = MockPetProvider();
    when(() => mockPetProvider.isLoading).thenReturn(false);
    when(() => mockPetProvider.pets).thenReturn([]);
    when(() => mockPetProvider.filters).thenReturn(['All', 'Dogs', 'Cats', 'Others']);
    when(() => mockPetProvider.selectedFilter).thenReturn('All');
    when(() => mockPetProvider.isLoadingMore).thenReturn(false);
  });

  Widget createTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LanguageProvider>.value(
          value: mockLanguageProvider,
        ),
        ChangeNotifierProvider<PetProvider>.value(
          value: mockPetProvider,
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: PetListScreen(),
        ),
      ),
    );
  }

  group('PetListScreen Widget Tests', () {
    testWidgets('should render search bar', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('should render filter chips', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Dogs'), findsOneWidget);
      expect(find.text('Cats'), findsOneWidget);
      expect(find.text('Others'), findsOneWidget);
    });

    testWidgets('should render filter list horizontally',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should show loading indicator initially',
        (WidgetTester tester) async {
      when(() => mockPetProvider.isLoading).thenReturn(true);

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show empty state when no pets',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.pets), findsOneWidget);
    });
  });
}
