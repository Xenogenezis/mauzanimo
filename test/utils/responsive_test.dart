import 'package:flutter_test/flutter_test.dart';
import 'package:stray_pets_mu/utils/responsive.dart';

void main() {
  group('gridColumnsForWidth', () {
    test('phones get 2 columns', () {
      for (final w in [280.0, 328.0, 360.0, 398.0, 430.0]) {
        expect(gridColumnsForWidth(w), 2, reason: 'width $w');
      }
    });

    test('tablets get 3-4 columns', () {
      expect(gridColumnsForWidth(736), 3);
      expect(gridColumnsForWidth(992), 4);
    });

    test('desktops get 4-6 columns', () {
      expect(gridColumnsForWidth(1248), 5);
      expect(gridColumnsForWidth(1408), 5);
      expect(gridColumnsForWidth(1888), 6);
    });

    test('caps at 6 columns on ultra-wide screens', () {
      expect(gridColumnsForWidth(5000), 6);
    });

    test('handles degenerate widths', () {
      expect(gridColumnsForWidth(0), 2);
      expect(gridColumnsForWidth(-10), 2);
      expect(gridColumnsForWidth(double.infinity), 2);
      expect(gridColumnsForWidth(double.nan), 2);
    });
  });

  group('useNavigationRail', () {
    test('switches at 840px', () {
      expect(useNavigationRail(400), isFalse);
      expect(useNavigationRail(839.9), isFalse);
      expect(useNavigationRail(840), isTrue);
      expect(useNavigationRail(1440), isTrue);
    });
  });
}
