import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:stray_pets_mu/utils/image_upload.dart';

/// A noisy image: worst case for JPEG, so it stays large at high quality.
Uint8List _noisyJpeg(int width, int height, {int quality = 100}) {
  final rnd = Random(1);
  final image = img.Image(width: width, height: height);
  for (final p in image) {
    p
      ..r = rnd.nextInt(256)
      ..g = rnd.nextInt(256)
      ..b = rnd.nextInt(256);
  }
  return img.encodeJpg(image, quality: quality);
}

void main() {
  group('shrinkImageToFit', () {
    test('leaves an image that already fits untouched', () {
      final small = _noisyJpeg(64, 64);
      expect(small.length, lessThan(kMaxUploadImageBytes));
      expect(identical(shrinkImageToFit(small), small), isTrue);
    });

    test('shrinks an oversized landscape photo under the limit', () {
      final big = _noisyJpeg(1600, 1200);
      expect(big.length, greaterThan(kMaxUploadImageBytes));

      final out = shrinkImageToFit(big);
      expect(out.length, lessThanOrEqualTo(kMaxUploadImageBytes));

      final decoded = img.decodeJpg(out)!;
      expect(decoded.width, lessThanOrEqualTo(1024));
      // Aspect ratio is kept.
      expect(decoded.width / decoded.height, closeTo(1600 / 1200, 0.02));
    });

    test('shrinks a portrait photo by its longest side', () {
      final big = _noisyJpeg(900, 1600);
      final out = shrinkImageToFit(big);
      expect(out.length, lessThanOrEqualTo(kMaxUploadImageBytes));

      final decoded = img.decodeJpg(out)!;
      expect(decoded.height, lessThanOrEqualTo(1024));
      expect(decoded.height, greaterThan(decoded.width));
    });

    test('honours a custom limit', () {
      final big = _noisyJpeg(800, 800);
      final out = shrinkImageToFit(big, maxBytes: 200 * 1024);
      expect(out.length, lessThanOrEqualTo(200 * 1024));
    });

    test('returns undecodable data unchanged', () {
      final junk = Uint8List.fromList(List.filled(kMaxUploadImageBytes + 10, 7));
      expect(identical(shrinkImageToFit(junk), junk), isTrue);
    });
  });
}
