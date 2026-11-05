import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stray_pets_mu/utils/jpeg_metadata.dart';

List<int> _seg(int marker, List<int> payload) {
  final len = payload.length + 2;
  return [0xFF, marker, len >> 8, len & 0xFF, ...payload];
}

/// Little-endian EXIF with Orientation=[orientation] and a GPS IFD pointer,
/// followed by a fake GPS marker string so the test can look for it.
List<int> _exif(int orientation) {
  final tiff = <int>[
    0x49, 0x49, 0x2A, 0x00, 0x08, 0x00, 0x00, 0x00, // II, 42, IFD0 at 8
    0x02, 0x00, // 2 entries
    0x12, 0x01, 0x03, 0x00, 0x01, 0x00, 0x00, 0x00, orientation, 0x00, 0x00, 0x00,
    0x25, 0x88, 0x04, 0x00, 0x01, 0x00, 0x00, 0x00, 0x26, 0x00, 0x00, 0x00, // GPS IFD
    0x00, 0x00, 0x00, 0x00,
    ...ascii.encode('GPS-20.1234,57.5678'),
  ];
  return _seg(0xE1, [...ascii.encode('Exif'), 0, 0, ...tiff]);
}

Uint8List _jpeg({int orientation = 6, bool withExif = true}) => Uint8List.fromList([
      0xFF, 0xD8,
      ..._seg(0xE0, [...ascii.encode('JFIF'), 0, 1, 1, 0, 0, 1, 0, 1, 0, 0]),
      if (withExif) ..._exif(orientation),
      ..._seg(0xE1, ascii.encode('http://ns.adobe.com/xap/1.0/\x00<x:xmpmeta>home</x:xmpmeta>')),
      ..._seg(0xED, ascii.encode('Photoshop 3.0 IPTC city')),
      ..._seg(0xFE, ascii.encode('secret comment')),
      ..._seg(0xDB, List.filled(65, 1)), // DQT
      0xFF, 0xDA, 0x00, 0x08, 1, 1, 0, 0, 0x3F, 0, // SOS header
      0x12, 0x34, 0xFF, 0x00, 0x56, // scan data
      0xFF, 0xD9,
    ]);

bool _contains(List<int> hay, String needle) =>
    latin1.decode(hay, allowInvalid: true).contains(needle);

void main() {
  test('removes GPS, XMP, IPTC and comments', () {
    final out = stripJpegMetadata(_jpeg());
    expect(_contains(out, 'GPS-20.1234'), isFalse);
    expect(_contains(out, 'xmpmeta'), isFalse);
    expect(_contains(out, 'IPTC'), isFalse);
    expect(_contains(out, 'secret comment'), isFalse);
  });

  test('keeps orientation, JFIF, tables and image data', () {
    final input = _jpeg(orientation: 6);
    final out = stripJpegMetadata(input);
    expect(out.sublist(0, 2), [0xFF, 0xD8]);
    expect(_contains(out, 'JFIF'), isTrue);
    expect(_contains(out, 'Exif'), isTrue);
    // Orientation entry: tag 0x0112, SHORT, count 1, value 6 (big-endian).
    final s = out.toList().join(',');
    expect(s.contains([0x01, 0x12, 0x00, 0x03, 0, 0, 0, 1, 0x00, 6].join(',')), isTrue);
    // Everything from SOS onward is untouched.
    final sos = input.indexOf(0xDA) - 1;
    expect(out.sublist(out.length - (input.length - sos)), input.sublist(sos));
  });

  test('no EXIF means no EXIF is added', () {
    final out = stripJpegMetadata(_jpeg(withExif: false));
    expect(_contains(out, 'Exif'), isFalse);
    expect(out.last, 0xD9);
  });

  test('non-JPEG and malformed input are returned unchanged', () {
    final png = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 1, 2, 3]);
    expect(identical(stripJpegMetadata(png), png), isTrue);
    final broken = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE1, 0x7F, 0xFF, 1]);
    expect(identical(stripJpegMetadata(broken), broken), isTrue);
  });
}
