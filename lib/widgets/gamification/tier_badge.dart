import 'package:flutter/material.dart';
import '../../models/user_gamification.dart';

/// Tier badge widget showing membership tier
/// Displays icon and optional label for the current tier
class TierBadge extends StatelessWidget {
  /// The membership tier to display
  final MembershipTier tier;

  /// Size of the badge (affects icon and container)
  final double size;

  /// Whether to show the text label
  final bool showLabel;

  const TierBadge({
    super.key,
    required this.tier,
    this.size = 32,
    this.showLabel = true,
  });

  /// Get the color associated with the tier
  Color get _tierColor {
    switch (tier) {
      case MembershipTier.supporter:
        return const Color(0xFF8B7355); // Bronze
      case MembershipTier.advocate:
        return const Color(0xFF2A9D8F); // Primary teal
      case MembershipTier.champion:
        return const Color(0xFFE9C46A); // Gold
      case MembershipTier.guardian:
        return const Color(0xFF264653); // Dark blue
    }
  }

  /// Get the icon for the tier
  IconData get _tierIcon {
    switch (tier) {
      case MembershipTier.supporter:
        return Icons.favorite_outline;
      case MembershipTier.advocate:
        return Icons.volunteer_activism;
      case MembershipTier.champion:
        return Icons.star;
      case MembershipTier.guardian:
        return Icons.shield;
    }
  }

  /// Get the display label for the tier
  String get _tierLabel {
    switch (tier) {
      case MembershipTier.supporter:
        return 'Supporter';
      case MembershipTier.advocate:
        return 'Advocate';
      case MembershipTier.champion:
        return 'Champion';
      case MembershipTier.guardian:
        return 'Guardian';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: showLabel ? 12 : size / 4,
        vertical: size / 8,
      ),
      decoration: BoxDecoration(
        color: _tierColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(size),
        border: Border.all(
          color: _tierColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _tierIcon,
            size: size * 0.6,
            color: _tierColor,
          ),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(
              _tierLabel,
              style: TextStyle(
                fontSize: size * 0.45,
                fontWeight: FontWeight.w600,
                color: _tierColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
