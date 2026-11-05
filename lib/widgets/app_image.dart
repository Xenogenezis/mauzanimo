import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Displays an image stored either as an https URL or as a
/// `data:image/...;base64,` URI (how uploads are currently stored).
class AppImage extends StatelessWidget {
  final String? source;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData placeholderIcon;

  /// Logical width the image is decoded at. Decoding a 1024px photo for a
  /// 160px card wastes memory and causes jank while scrolling.
  final double decodeWidth;

  const AppImage(
    this.source, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholderIcon = Icons.pets,
    this.decodeWidth = 480,
  });

  static final Map<String, Uint8List> _decoded = {};

  static Uint8List? _decode(String dataUri) {
    final cached = _decoded[dataUri];
    if (cached != null) return cached;
    final comma = dataUri.indexOf(',');
    if (comma < 0) return null;
    try {
      final bytes = base64Decode(dataUri.substring(comma + 1));
      if (_decoded.length > 64) _decoded.clear();
      _decoded[dataUri] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final src = source?.trim() ?? '';
    final placeholder = Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Icon(placeholderIcon, color: Colors.grey.shade400, size: 32),
    );
    if (src.isEmpty) return placeholder;
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
    final cacheWidth = (decodeWidth * dpr).round();

    if (src.startsWith('data:')) {
      final bytes = _decode(src);
      if (bytes == null) return placeholder;
      return Image.memory(bytes,
          width: width, height: height, fit: fit, gaplessPlayback: true,
          cacheWidth: cacheWidth,
          errorBuilder: (_, __, ___) => placeholder);
    }
    if (src.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: src,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: cacheWidth,
        placeholder: (_, __) => placeholder,
        errorWidget: (_, __, ___) => placeholder,
      );
    }
    return placeholder;
  }
}
