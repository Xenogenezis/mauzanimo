/// Pure layout helpers for adapting the UI to phone, tablet and desktop widths.
library;

/// Target width of a single pet card in a grid, in logical pixels.
const double kGridTargetTileWidth = 240;

/// Minimum and maximum number of grid columns.
const int kGridMinColumns = 2;
const int kGridMaxColumns = 6;

/// Width at and above which the app switches from a bottom navigation bar
/// to a navigation rail (Material 3 "medium/expanded" window class).
const double kNavigationRailBreakpoint = 840;

/// Number of grid columns for a grid of [width] logical pixels.
///
/// Phones always get [kGridMinColumns] (2) columns; wider layouts get one
/// column per ~[kGridTargetTileWidth] pixels, capped at [kGridMaxColumns].
int gridColumnsForWidth(double width) {
  if (!width.isFinite || width <= 0) return kGridMinColumns;
  final columns = (width / kGridTargetTileWidth).floor();
  return columns.clamp(kGridMinColumns, kGridMaxColumns);
}

/// Whether a window of [width] logical pixels should use a NavigationRail.
bool useNavigationRail(double width) => width >= kNavigationRailBreakpoint;
