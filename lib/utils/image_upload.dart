import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:stray_pets_mu/utils/jpeg_metadata.dart';

/// Largest photo stored with a post. Photos are saved as base64 inside the
/// Firestore document (1 MB document limit; `firestore.rules` caps the
/// encoded string at 850,000 characters, about 620 KB of image), so this
/// leaves room for the other fields.
const int kMaxUploadImageBytes = 500 * 1024;

/// Longest side and JPEG quality asked of the picker. A phone photo comes
/// out at roughly 150-350 KB, sharp enough for a full-screen pet photo.
const int _pickSide = 1280;
const int _pickQuality = 75;

/// Progressively smaller (longest side, JPEG quality) attempts used when the
/// picker's own resize was not enough.
const List<(int, int)> _shrinkSteps = [(1024, 70), (800, 60), (640, 50), (480, 40)];

/// Lets the user pick or take a photo and returns it ready to store: resized,
/// compressed to at most [kMaxUploadImageBytes] and with GPS/EXIF metadata
/// removed. Returns null when the user cancels.
///
/// The user never has to find a smaller file: whatever they pick is shrunk
/// until it fits.
Future<Uint8List?> pickUploadImage(ImagePicker picker, ImageSource source) async {
  final picked = await picker.pickImage(
    source: source,
    imageQuality: _pickQuality,
    maxWidth: _pickSide.toDouble(),
    maxHeight: _pickSide.toDouble(),
  );
  if (picked == null) return null;
  var bytes = await picked.readAsBytes();
  if (bytes.length > kMaxUploadImageBytes) {
    // Rare: the picker could not resize the file (some formats and browsers)
    // or the photo is unusually detailed.
    bytes = await compute(shrinkImageToFit, bytes);
  }
  return stripJpegMetadata(bytes);
}

/// Re-encodes [bytes] as a smaller JPEG until it is at most [maxBytes].
///
/// Returns [bytes] unchanged when it already fits or cannot be decoded.
Uint8List shrinkImageToFit(Uint8List bytes, {int maxBytes = kMaxUploadImageBytes}) {
  if (bytes.length <= maxBytes) return bytes;
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;
  // Rotate the pixels so the result displays upright without EXIF.
  final image = img.bakeOrientation(decoded);

  var out = bytes;
  for (final (side, quality) in _shrinkSteps) {
    final longest = math.max(image.width, image.height);
    final resized = longest <= side
        ? image
        : img.copyResize(
            image,
            width: image.width >= image.height ? side : null,
            height: image.width >= image.height ? null : side,
            interpolation: img.Interpolation.average,
          );
    out = img.encodeJpg(resized, quality: quality);
    if (out.length <= maxBytes) break;
  }
  return out;
}
