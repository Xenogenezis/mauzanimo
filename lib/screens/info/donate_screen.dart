import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../theme/adaptive_colors.dart';
import '../../lang/app_strings.dart';
import '../../providers/language_provider.dart';

class DonateScreen extends StatelessWidget {
  const DonateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).lang;
    final textColor = context.textStrong;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('donate', lang)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(Icons.favorite, size: 80, color: Colors.red.shade400),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                AppStrings.get('support_mauzanimo', lang),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                AppStrings.get('your_donation_helps_stray_pets_find_lovi', lang),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _InfoCard(
              icon: Icons.medical_services_outlined,
              color: Colors.red,
              title: AppStrings.get('vet_care', lang),
              description: AppStrings.get('vet_care_desc', lang),
            ),
            const SizedBox(height: 12),
            _InfoCard(
              icon: Icons.home_outlined,
              color: Colors.orange,
              title: AppStrings.get('shelter_support', lang),
              description: AppStrings.get('shelter_support_desc', lang),
            ),
            const SizedBox(height: 12),
            _InfoCard(
              icon: Icons.campaign_outlined,
              color: AppTheme.primary,
              title: AppStrings.get('awareness_campaigns', lang),
              description: AppStrings.get('awareness_campaigns_desc', lang),
            ),
            const SizedBox(height: 32),
            Text(
              AppStrings.get('bank_transfer_details', lang),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.mutedFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final key in const [
                    'bank_mcb_mauritius',
                    'account_name_jci_grand_baie',
                    'account_no_xxxxxxxxxxxx',
                    'reference_mauzanimo_donation',
                  ])
                    CopyableDetail(
                      text: AppStrings.get(key, lang),
                      lang: lang,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _contactForAlternativePayment(context, lang),
                icon: const Icon(Icons.email_outlined),
                label: Text(
                  AppStrings.get('contact_us_for_other_payment_methods', lang),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _contactForAlternativePayment(BuildContext context, String lang) async {
    const email = 'jcigrandbaie@gmail.com';
    final subject = Uri.encodeComponent(AppStrings.get('ui_donate_email_subject', lang));
    final body = Uri.encodeComponent(AppStrings.get('ui_donate_email_body', lang));

    final uri = Uri.parse('mailto:$email?subject=$subject&body=$body');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.get('ui_could_not_open_email', lang)),
          ),
        );
      }
    }
  }
}

/// The part of a "Label: value" line worth copying (the value).
String copyValueOf(String line) {
  final i = line.indexOf(':');
  if (i < 0) return line.trim();
  final value = line.substring(i + 1).trim();
  return value.isEmpty ? line.trim() : value;
}

/// A payment detail line; tapping copies its value to the clipboard.
class CopyableDetail extends StatelessWidget {
  final String text;
  final String lang;

  const CopyableDetail({super.key, required this.text, required this.lang});

  @override
  Widget build(BuildContext context) {
    final textColor = context.textStrong;
    return Tooltip(
      message: AppStrings.get('alerts_tap_to_copy', lang),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          final messenger = ScaffoldMessenger.of(context);
          final copied = AppStrings.get('alerts_copied', lang);
          await Clipboard.setData(ClipboardData(text: copyValueOf(text)));
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
                content: Text(copied),
                duration: const Duration(seconds: 2)));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Expanded(
              child: Text(text,
                  style: TextStyle(fontSize: 14, color: textColor)),
            ),
            Icon(Icons.copy, size: 16,
                color: textColor.withValues(alpha: 0.5)),
          ]),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _InfoCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: context.textStrong,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
