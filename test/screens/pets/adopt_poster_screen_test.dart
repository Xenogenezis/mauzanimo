import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/screens/pets/adopt_poster_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestWidget(Map<String, dynamic> pet) {
    return ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: MaterialApp(home: AdoptPosterScreen(pet: pet, petId: 'pet1')),
    );
  }

  final pet = <String, dynamic>{
    'name': 'Biscuit',
    'type': 'dogs',
    'age': '2 years',
    'gender': 'Male',
    'description': 'Playful and gentle, loves walks on the beach.',
    'location': 'Grand Baie',
    'contact': '5712 3456',
    'imageUrl': '',
    'vaccinated': true,
    'sterilized': true,
    'dewormed': false,
    'status': 'available',
  };

  testWidgets('shows ADOPT ME header, details, badges and contact', (tester) async {
    await tester.pumpWidget(createTestWidget(pet));
    await tester.pump();

    expect(find.text('ADOPT ME'), findsOneWidget);
    expect(find.text('Biscuit'), findsOneWidget);
    expect(find.text('Dog  ·  Age: 2 years  ·  Male'), findsOneWidget);
    expect(find.text('Vaccinated'), findsOneWidget);
    expect(find.text('Sterilised'), findsOneWidget);
    expect(find.text('Dewormed'), findsNothing);
    expect(find.text('5712 3456'), findsOneWidget);
    expect(find.text('MauZanimo - Rehome responsibly. Adopt locally.'), findsOneWidget);
    expect(find.text('Share poster'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses the selected language', (tester) async {
    SharedPreferences.setMockInitialValues({'language': 'fr'});
    await tester.pumpWidget(createTestWidget(pet));
    await tester.pump();

    expect(find.text('ADOPTEZ-MOI'), findsOneWidget);
    expect(find.text('Vacciné'), findsOneWidget);
    expect(find.text('5712 3456'), findsOneWidget);
  });

  testWidgets('handles missing optional fields', (tester) async {
    await tester.pumpWidget(createTestWidget({'name': 'Mimi'}));
    await tester.pump();

    expect(find.text('ADOPT ME'), findsOneWidget);
    expect(find.text('Mimi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fits on a small phone screen without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createTestWidget({
      ...pet,
      'dewormed': true,
      'description': 'A very long description ' * 20,
      'location': 'Somewhere with a very long place name, Mauritius ' * 3,
    }));
    await tester.pump();

    expect(find.text('ADOPT ME'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stays within its max width on a wide web screen', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createTestWidget(pet));
    await tester.pump();

    expect(find.text('ADOPT ME'), findsOneWidget);
    expect(tester.getSize(find.byType(AspectRatio).first).width,
        lessThanOrEqualTo(480));
    expect(tester.takeException(), isNull);
  });

  test('type labels are localised and singular', () {
    expect(adoptPosterTypeLabel('dogs', 'en'), 'Dog');
    expect(adoptPosterTypeLabel('cats', 'fr'), 'Chat');
    expect(adoptPosterTypeLabel('others', 'mfe'), 'Zanimo');
    expect(adoptPosterTypeLabel('rabbit', 'en'), 'rabbit');
    expect(adoptPosterTypeLabel(null, 'en'), '');
  });
}
