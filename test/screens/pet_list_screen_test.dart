import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stray_pets_mu/screens/pets/pet_list_screen.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/providers/pet_provider.dart';
import 'package:stray_pets_mu/models/pet.dart';
import 'package:stray_pets_mu/models/pet_filters.dart';
import 'package:stray_pets_mu/screens/pets/pet_card.dart';

class MockLanguageProvider extends Mock implements LanguageProvider {}

class MockPetProvider extends Mock implements PetProvider {}

void main() {
  late MockLanguageProvider mockLanguageProvider;
  late MockPetProvider mockPetProvider;

  Pet pet(String id) => Pet(
        id: id,
        name: id,
        type: 'dogs',
        location: 'Grand Baie',
        description: '',
        age: '2 years',
        gender: 'Male',
        contact: '',
        createdAt: DateTime(2026, 11, 3),
      );

  setUpAll(() {
    registerFallbackValue(PetFilters.none);
    registerFallbackValue(pet('fallback'));
  });

  setUp(() {
    mockLanguageProvider = MockLanguageProvider();
    when(() => mockLanguageProvider.lang).thenReturn('en');

    mockPetProvider = MockPetProvider();
    when(() => mockPetProvider.isLoading).thenReturn(false);
    when(() => mockPetProvider.pets).thenReturn([]);
    when(() => mockPetProvider.filters).thenReturn(['All', 'Dogs', 'Cats', 'Others']);
    when(() => mockPetProvider.selectedFilter).thenReturn('All');
    when(() => mockPetProvider.isLoadingMore).thenReturn(false);
    when(() => mockPetProvider.listFilters).thenReturn(PetFilters.none);
    when(() => mockPetProvider.searchQuery).thenReturn('');
    when(() => mockPetProvider.showNewBanner).thenReturn(false);
    when(() => mockPetProvider.newPetCount).thenReturn(0);
    when(() => mockPetProvider.isNewPet(any())).thenReturn(false);
    when(() => mockPetProvider.markVisited()).thenAnswer((_) async {});
    when(() => mockPetProvider.savedSearches).thenReturn(const []);
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

  testWidgets('filter button opens the filter sheet', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    expect(find.text('Filter & sort'), findsWidgets);
    expect(find.text('Newest'), findsOneWidget);
    expect(find.text('Show pets'), findsOneWidget);
  });

  testWidgets('applying the sheet passes filters to the provider',
      (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Female'));
    await tester.pump();
    await tester.ensureVisible(find.text('Show pets'));
    await tester.tap(find.text('Show pets'));
    await tester.pumpAndSettle();
    final captured =
        verify(() => mockPetProvider.setListFilters(captureAny())).captured;
    expect((captured.single as PetFilters).gender, 'female');
  });

  testWidgets('shows the new-pets banner and NEW ribbon', (tester) async {
    final fresh = pet('Fresh');
    final old = pet('Old');
    when(() => mockPetProvider.pets).thenReturn([fresh, old]);
    when(() => mockPetProvider.showNewBanner).thenReturn(true);
    when(() => mockPetProvider.newPetCount).thenReturn(1);
    when(() => mockPetProvider.isNewPet(fresh)).thenReturn(true);
    when(() => mockPetProvider.isNewPet(old)).thenReturn(false);
    when(() => mockPetProvider.hasMore).thenReturn(false);

    await tester.pumpWidget(createTestWidget());
    await tester.pump();

    expect(find.text('1 new pet since your last visit'), findsOneWidget);
    expect(find.text('NEW'), findsOneWidget);
    final cards = tester.widgetList<PetCard>(find.byType(PetCard)).toList();
    expect(cards.map((c) => c.isNew), [true, false]);

    await tester.tap(find.byTooltip('Dismiss'));
    verify(() => mockPetProvider.dismissNewBanner()).called(1);
  });

  testWidgets('filter sheet offers Save this search', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    expect(find.text('Save this search'), findsOneWidget);
  });

  testWidgets('My alerts button opens the saved searches sheet',
      (tester) async {
    when(() => mockPetProvider.recentPetsForAlerts())
        .thenAnswer((_) async => []);
    await tester.pumpWidget(createTestWidget());
    await tester.tap(find.byTooltip('My alerts'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No saved searches yet'), findsOneWidget);
  });

  testWidgets('leaving the list records the visit', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpWidget(const SizedBox());
    verify(() => mockPetProvider.markVisited()).called(1);
  });
}
