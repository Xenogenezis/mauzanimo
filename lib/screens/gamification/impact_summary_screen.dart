import 'package:flutter/material.dart';
import '../../models/user_gamification.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gamification/impact_ring.dart';
import '../../widgets/gamification/tier_badge.dart';

/// Weekly impact summary screen
/// Shows user's weekly activity summary with points earned and highlights
class ImpactSummaryScreen extends StatelessWidget {
  /// The weekly summary data to display
  final WeeklySummary summary;

  /// Current user gamification data for context
  final UserGamification gamification;

  /// Callback when user dismisses the summary
  final VoidCallback? onDismiss;

  const ImpactSummaryScreen({
    super.key,
    required this.summary,
    required this.gamification,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              // Header
              Text(
                'Weekly Impact Summary',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Week of ${_formatDate(summary.weekStarting)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),

              // Impact Ring
              ImpactRing(
                progress: gamification.tierProgress,
                points: gamification.totalPoints,
                pointsToNext: gamification.pointsToNextTier,
                tierName: gamification.tierDisplayName,
                tierColor: gamification.tierColor,
                size: 140,
              ),
              const SizedBox(height: 32),

              // Weekly Stats
              _buildStatsCard(theme),
              const SizedBox(height: 24),

              // Highlights
              if (summary.highlights.isNotEmpty) ...[
                _buildHighlightsCard(theme),
                const SizedBox(height: 24),
              ],

              // Current Tier
              _buildTierCard(theme),
              const SizedBox(height: 40),

              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onDismiss ?? () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'This Week',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                theme,
                Icons.star,
                '+${summary.pointsEarned}',
                'Points Earned',
                AppTheme.accent,
              ),
              Container(
                height: 50,
                width: 1,
                color: Colors.grey.shade200,
              ),
              _buildStatItem(
                theme,
                Icons.check_circle,
                '${summary.actionsCount}',
                'Actions',
                AppTheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightsCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Highlights',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...summary.highlights.map((highlight) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    highlight,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTierCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gamification.tierColor.withValues(alpha: 0.1),
            gamification.tierColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: gamification.tierColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          TierBadge(
            tier: gamification.tier,
            size: 40,
          ),
          const SizedBox(height: 16),
          Text(
            gamification.tier == MembershipTier.guardian
                ? 'You\'ve reached the highest tier!'
                : '${gamification.pointsToNextTier} points to ${UserGamification.calculateTier(gamification.totalPoints + gamification.pointsToNextTier).name}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textDark,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
