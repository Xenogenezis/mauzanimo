import 'dart:typed_data';

/// Removes privacy-sensitive metadata from a JPEG before it is uploaded.
///
/// image_picker on Android and iOS copies the original EXIF block (including
/// GPS coordinates, often the poster's home) into resized photos, and pet,
/// lost & found and sighting posts are public. This drops EXIF/XMP (APP1),
/// IPTC (APP13) and comment segments, but keeps a minimal EXIF block holding
/// only the Orientation tag, because the pixels are not rotated and the
/// photo would otherwise display sideways.
///
/// Anything that is not a well-formed JPEG is returned unchanged.
Uint8List stripJpegMetadata(Uint8List bytes) {
  if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) return bytes;

  final out = BytesBuilder(copy: false)..add(const [0xFF, 0xD8]);
  var i = 2;
  var orientationWritten = false;

  while (i < bytes.length) {
    if (bytes[i] != 0xFF) return bytes; // malformed
    if (i + 1 >= bytes.length) return bytes;
    final marker = bytes[i + 1];

    if (marker == 0xFF) {
      i++; // fill byte
      continue;
    }
    // Start of scan: the rest is entropy-coded image data.
    if (marker == 0xDA) {
      out.add(Uint8List.sublistView(bytes, i));
      return out.toBytes();
    }
    // Standalone markers without a length.
    if (marker == 0xD8 || marker == 0xD9 || marker == 0x01 ||
        (marker >= 0xD0 && marker <= 0xD7)) {
      out.add(Uint8List.sublistView(bytes, i, i + 2));
      i += 2;
      if (marker == 0xD9) return out.toBytes();
      continue;
    }

    if (i + 4 > bytes.length) return bytes;
    final len = (bytes[i + 2] << 8) | bytes[i + 3];
    final end = i + 2 + len;
    if (len < 2 || end > bytes.length) return bytes;

    final isApp1 = marker == 0xE1;
    final isIptc = marker == 0xED;
    final isComment = marker == 0xFE;

    if (isApp1) {
      if (!orientationWritten && _isExif(bytes, i + 4, end)) {
        final orientation = _readOrientation(bytes, i + 10, end);
        if (orientation != null) out.add(_minimalExif(orientation));
        orientationWritten = true;
      }
    } else if (!isIptc && !isComment) {
      out.add(Uint8List.sublistView(bytes, i, end));
    }
    i = end;
  }
  return out.toBytes();
}

bool _isExif(Uint8List b, int start, int end) =>
    end - start >= 6 &&
    b[start] == 0x45 && // E
    b[start + 1] == 0x78 && // x
    b[start + 2] == 0x69 && // i
    b[start + 3] == 0x66 && // f
    b[start + 4] == 0 &&
    b[start + 5] == 0;

/// Reads tag 0x0112 from IFD0 of the TIFF structure starting at [tiff].
int? _readOrientation(Uint8List b, int tiff, int end) {
  if (tiff + 8 > end) return null;
  final bool little;
  if (b[tiff] == 0x49 && b[tiff + 1] == 0x49) {
    little = true;
  } else if (b[tiff] == 0x4D && b[tiff + 1] == 0x4D) {
    little = false;
  } else {
    return null;
  }
  int u16(int o) => little ? b[o] | (b[o + 1] << 8) : (b[o] << 8) | b[o + 1];
  int u32(int o) => little
      ? b[o] | (b[o + 1] << 8) | (b[o + 2] << 16) | (b[o + 3] << 24)
      : (b[o] << 24) | (b[o + 1] << 16) | (b[o + 2] << 8) | b[o + 3];

  final ifd = tiff + u32(tiff + 4);
  if (ifd + 2 > end) return null;
  final count = u16(ifd);
  for (var e = 0; e < count; e++) {
    final entry = ifd + 2 + e * 12;
    if (entry + 12 > end) return null;
    if (u16(entry) == 0x0112) {
      final value = u16(entry + 8);
      return value >= 1 && value <= 8 ? value : null;
    }
  }
  return null;
}

/// APP1 segment with a big-endian TIFF header and a single Orientation tag.
Uint8List _minimalExif(int orientation) => Uint8List.fromList([
      0xFF, 0xE1, 0x00, 0x22, // APP1, length 34
      0x45, 0x78, 0x69, 0x66, 0x00, 0x00, // "Exif\0\0"
      0x4D, 0x4D, 0x00, 0x2A, 0x00, 0x00, 0x00, 0x08, // MM, 42, IFD0 at 8
      0x00, 0x01, // one entry
      0x01, 0x12, 0x00, 0x03, 0x00, 0x00, 0x00, 0x01, // Orientation, SHORT, 1
      0x00, orientation, 0x00, 0x00, // value
      0x00, 0x00, 0x00, 0x00, // no next IFD
    ]);
