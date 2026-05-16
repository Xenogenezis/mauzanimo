import 'package:flutter/material.dart';
import 'package:stray_pets_mu/models/verification_badge.dart';

class VerificationBadgeWidget extends StatelessWidget {
  final VerificationLevel level;
  final double size;

  const VerificationBadgeWidget({super.key, required this.level, this.size = 16});

  @override
  Widget build(BuildContext context) {
    final badge = VerificationBadge.fromLevel(level);
    if (level == VerificationLevel.none) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badge.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badge.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badge.icon, size: size, color: badge.color),
          const SizedBox(width: 6),
          Text(
            badge.displayName,
            style: TextStyle(fontSize: size, fontWeight: FontWeight.w600, color: badge.color),
          ),
        ],
      ),
    );
  }
}

class VerificationLevelPicker extends StatelessWidget {
  final VerificationLevel currentLevel;
  final ValueChanged<VerificationLevel> onChanged;

  const VerificationLevelPicker({
    super.key,
    required this.currentLevel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: VerificationBadge.allBadges.map((badge) {
        final isSelected = badge.level == currentLevel;
        return ListTile(
          leading: Icon(
            badge.icon,
            color: isSelected ? badge.color : Colors.grey,
          ),
          title: Text(
            badge.displayName,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? badge.color : null,
            ),
          ),
          trailing: isSelected
              ? Icon(Icons.check_circle, color: badge.color)
              : null,
          onTap: () => onChanged(badge.level),
        );
      }).toList(),
    );
  }
}
