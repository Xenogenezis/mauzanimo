import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stray_pets_mu/theme/app_theme.dart';

void main() {
  testWidgets('App theme should have correct primary color',
      (WidgetTester tester) async {
    expect(AppTheme.primary, const Color(0xFF2A9D8F));
  });

  testWidgets('App theme accent should have correct color',
      (WidgetTester tester) async {
    expect(AppTheme.accent, const Color(0xFFE9C46A));
  });
}
