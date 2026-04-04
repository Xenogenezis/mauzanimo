import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../lang/app_strings.dart';
import '../../providers/language_provider.dart';

class DonateScreen extends StatelessWidget {
  const DonateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).lang;

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
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
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
                  color: AppTheme.textDark.withOpacity(0.6),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _InfoCard(
              icon: Icons.medical_services_outlined,
              color: Colors.red,
              title: lang == 'fr' ? 'Soins veterinaires' : 'Veterinary Care',
              description: lang == 'fr'
                  ? 'Aidez a couvrir les frais medicaux des animaux secourus'
                  : 'Help cover medical costs for rescued animals',
            ),
            const SizedBox(height: 12),
            _InfoCard(
              icon: Icons.home_outlined,
              color: Colors.orange,
              title: lang == 'fr' ? 'Soutien aux refuges' : 'Shelter Support',
              description: lang == 'fr'
                  ? 'Financez les operations et les soins des animaux'
                  : 'Fund shelter operations and animal care',
            ),
            const SizedBox(height: 12),
            _InfoCard(
              icon: Icons.campaign_outlined,
              color: AppTheme.primary,
              title: lang == 'fr' ? 'Campagnes de sensibilisation' : 'Awareness Campaigns',
              description: lang == 'fr'
                  ? 'Diffusez le message sur la responsabilite des animaux de compagnie'
                  : 'Spread the word about responsible pet ownership',
            ),
            const SizedBox(height: 32),
            Text(
              AppStrings.get('bank_transfer_details', lang),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.lightGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.get('bank_mcb_mauritius', lang),
                    style: TextStyle(fontSize: 14, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppStrings.get('account_name_jci_grand_baie', lang),
                    style: TextStyle(fontSize: 14, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppStrings.get('account_no_xxxxxxxxxxxx', lang),
                    style: TextStyle(fontSize: 14, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppStrings.get('reference_mauzanimo_donation', lang),
                    style: TextStyle(fontSize: 14, color: AppTheme.textDark),
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
    final email = 'mauzanimo@jcigrandbaie.org';
    final subject = Uri.encodeComponent(
      lang == 'fr'
          ? 'Demande de don - Autres methodes de paiement'
          : 'Donation Inquiry - Alternative Payment Methods',
    );
    final body = Uri.encodeComponent(
      lang == 'fr'
          ? 'Bonjour,\n\nJe souhaite faire un don a MauZanimo et jaimerais connaitre les autres methodes de paiement disponibles.\n\nCordialement,'
          : 'Hello,\n\nI would like to make a donation to MauZanimo and would like to know about alternative payment methods available.\n\nBest regards,',
    );

    final uri = Uri.parse('mailto:$email?subject=$subject&body=$body');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang == 'fr'
                  ? 'Impossible d\'ouvrir l\'application email'
                  : 'Could not open email app',
            ),
          ),
        );
      }
    }
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              color: color.withOpacity(0.1),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
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
