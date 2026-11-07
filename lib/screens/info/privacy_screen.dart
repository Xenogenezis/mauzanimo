import 'package:stray_pets_mu/utils/app_contact.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/theme/adaptive_colors.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';

/// Contact address for privacy requests (same as the Contact screen).
const String privacyContactEmail = kContactEmail;

/// Privacy policy under the Mauritius Data Protection Act 2017.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const List<(String, String, IconData)> sections = [
    ('privacy_collect_title', 'privacy_collect_body', Icons.inventory_2_outlined),
    ('privacy_why_title', 'privacy_why_body', Icons.help_outline),
    ('privacy_who_title', 'privacy_who_body', Icons.visibility_outlined),
    ('privacy_photos_title', 'privacy_photos_body', Icons.photo_camera_outlined),
    ('privacy_retention_title', 'privacy_retention_body', Icons.schedule_outlined),
    ('privacy_rights_title', 'privacy_rights_body', Icons.gavel_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    String t(String k) => AppStrings.get(k, lang);
    final textColor = context.textStrong;
    return Scaffold(
      backgroundColor: context.pageBackground,
      appBar: AppBar(title: Text(t('privacy_title'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Center(child: Icon(Icons.privacy_tip_outlined, size: 64, color: AppTheme.primary)),
            const SizedBox(height: 16),
            Text(t('privacy_intro'),
                style: TextStyle(fontSize: 15, height: 1.4, color: textColor)),
            const SizedBox(height: 8),
            for (final (title, body, icon) in sections)
              _Section(icon: icon, title: t(title), body: t(body)),
            _Section(
              icon: Icons.mail_outline,
              title: t('privacy_contact_title'),
              body: t('privacy_contact_body'),
              trailing: SelectableText(privacyContactEmail,
                  onTap: () => Clipboard.setData(
                      const ClipboardData(text: privacyContactEmail)),
                  style: const TextStyle(
                      color: AppTheme.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Widget? trailing;

  const _Section({required this.icon, required this.title, required this.body, this.trailing});

  @override
  Widget build(BuildContext context) {
    final textColor = context.textStrong;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 20, color: AppTheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textColor)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(body,
              style: TextStyle(fontSize: 14, height: 1.45, color: textColor.withValues(alpha: 0.8))),
          if (trailing != null) ...[const SizedBox(height: 6), trailing!],
        ],
      ),
    );
  }
}
