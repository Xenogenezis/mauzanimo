import 'package:flutter/material.dart';

enum VerificationLevel {
  none,
  emailVerified,
  phoneVerified,
  homeCheckDone,
  pastAdoptionCompleted,
}

class VerificationBadge {
  final VerificationLevel level;
  final String displayName;
  final IconData icon;
  final Color color;

  const VerificationBadge({
    required this.level,
    required this.displayName,
    required this.icon,
    required this.color,
  });

  static VerificationBadge fromLevel(VerificationLevel level) => allBadges.firstWhere(
        (b) => b.level == level,
        orElse: () => allBadges[0],
      );

  static List<VerificationBadge> get allBadges => [
        const VerificationBadge(level: VerificationLevel.none, displayName: 'Not Verified', icon: Icons.help_outline, color: Colors.grey),
        const VerificationBadge(level: VerificationLevel.emailVerified, displayName: 'Email Verified', icon: Icons.email_outlined, color: Colors.blue),
        const VerificationBadge(level: VerificationLevel.phoneVerified, displayName: 'Phone Verified', icon: Icons.phone_android_outlined, color: Colors.teal),
        const VerificationBadge(level: VerificationLevel.homeCheckDone, displayName: 'Home Check Done', icon: Icons.home_work_outlined, color: Colors.orange),
        const VerificationBadge(level: VerificationLevel.pastAdoptionCompleted, displayName: 'Trusted Adopter', icon: Icons.verified, color: Colors.green),
      ];
}
