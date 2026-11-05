import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stray_pets_mu/widgets/adaptive_nav_scaffold.dart';

void main() {
  Widget buildApp(ValueChanged<int> onSelected, {int index = 0}) {
    return MaterialApp(
      home: AdaptiveNavScaffold(
        currentIndex: index,
        onDestinationSelected: onSelected,
        appBar: AppBar(title: const Text('MauZanimo')),
        destinations: const [
          AdaptiveNavDestination(icon: Icons.pets, label: 'Pets'),
          AdaptiveNavDestination(icon: Icons.favorite_outline, label: 'Saved'),
          AdaptiveNavDestination(icon: Icons.person_outline, label: 'Profile'),
        ],
        body: Text('body $index'),
      ),
    );
  }

  void setSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('desktop width shows a NavigationRail', (tester) async {
    setSize(tester, const Size(1280, 800));
    int? selected;
    await tester.pumpWidget(buildApp((i) => selected = i));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.text('Pets'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('body 0'), findsOneWidget);

    await tester.tap(find.text('Saved'));
    expect(selected, 1);
  });

  testWidgets('phone width shows a BottomNavigationBar', (tester) async {
    setSize(tester, const Size(390, 844));
    int? selected;
    await tester.pumpWidget(buildApp((i) => selected = i));

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Profile'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    expect(selected, 2);
  });

  testWidgets('switches at the 840px breakpoint', (tester) async {
    setSize(tester, const Size(839, 800));
    await tester.pumpWidget(buildApp((_) {}));
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    setSize(tester, const Size(840, 800));
    await tester.pumpWidget(buildApp((_) {}));
    expect(find.byType(NavigationRail), findsOneWidget);
  });
}
