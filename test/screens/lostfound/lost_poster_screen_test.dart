import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/screens/lostfound/lost_poster_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestWidget(Map<String, dynamic> data) {
    return ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: MaterialApp(home: LostPosterScreen(data: data)),
    );
  }

  final lostReport = <String, dynamic>{
    'type': 'Lost',
    'animalType': 'Dog',
    'description': 'Brown dog with a red collar, very friendly.',
    'location': 'Grand Baie, near the market',
    'contact': '5712 3456',
    'imageUrl': '',
    'createdAt': Timestamp.fromDate(DateTime(2026, 10, 3)),
  };

  testWidgets('shows LOST header, details and contact', (tester) async {
    await tester.pumpWidget(createTestWidget(lostReport));
    await tester.pump();

    expect(find.text('LOST'), findsOneWidget);
    expect(find.text('5712 3456'), findsOneWidget);
    expect(find.text('Dog'), findsOneWidget);
    expect(find.text('Please call if you have seen this animal'), findsOneWidget);
    expect(find.text('Share poster'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows FOUND header for found reports', (tester) async {
    await tester.pumpWidget(createTestWidget({...lostReport, 'type': 'Found'}));
    await tester.pump();

    expect(find.text('FOUND'), findsOneWidget);
    expect(find.text('LOST'), findsNothing);
  });

  testWidgets('uses the selected language', (tester) async {
    SharedPreferences.setMockInitialValues({'language': 'fr'});
    await tester.pumpWidget(createTestWidget(lostReport));
    await tester.pump();

    expect(find.text('PERDU'), findsOneWidget);
    expect(find.text('5712 3456'), findsOneWidget);
  });

  testWidgets('fits on a small phone screen without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createTestWidget(lostReport));
    await tester.pump();

    expect(find.text('LOST'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
