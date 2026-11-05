import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Colours that keep the brand look in light mode but follow the
/// [ColorScheme] in dark mode, so text and cards stay readable.
extension AdaptiveColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Main text colour: [AppTheme.textDark] in light mode, onSurface in dark.
  Color get textStrong =>
      isDarkMode ? Theme.of(this).colorScheme.onSurface : AppTheme.textDark;

  /// Card background: white in light mode, a raised surface in dark.
  Color get cardBackground => isDarkMode
      ? Theme.of(this).colorScheme.surfaceContainerHighest
      : Colors.white;

  /// Muted fill (chips, info boxes): [AppTheme.lightGrey] in light mode.
  Color get mutedFill => isDarkMode
      ? Theme.of(this).colorScheme.surfaceContainerHighest
      : AppTheme.lightGrey;

  /// Page background: [AppTheme.background] in light mode, the theme's
  /// scaffold colour in dark.
  Color get pageBackground => isDarkMode
      ? Theme.of(this).scaffoldBackgroundColor
      : AppTheme.background;
}
