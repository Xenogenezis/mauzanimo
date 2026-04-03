import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/lang/language_provider.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';
import 'package:stray_pets_mu/screens/auth/login_screen.dart';
import 'package:stray_pets_mu/screens/info/donate_screen.dart';
import 'package:stray_pets_mu/screens/info/partners_screen.dart';
import 'package:stray_pets_mu/screens/info/contact_screen.dart';
import 'package:stray_pets_mu/screens/info/about_screen.dart';
import 'package:stray_pets_mu/screens/info/volunteer_screen.dart';
import 'package:stray_pets_mu/screens/stories/success_stories_screen.dart';
import 'package:stray_pets_mu/screens/lostfound/lost_found_screen.dart';
import 'package:stray_pets_mu/screens/events/events_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final lang = Provider.of<LanguageProvider>(context).lang;
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
            decoration: const BoxDecoration(color: AppTheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset('assets/images/jci_grand_baie.png', height: 60),
                const SizedBox(height: 16),
                Text('MauZanimo',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(user?.email ?? 'Guest',
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8))),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 8),
                _DrawerTile(
                  icon: Icons.search,
                  title: AppStrings.get('lost_found', lang),
                  subtitle: lang == 'fr' ? 'Signalez ou trouvez des animaux' : 'Report or find lost animals',
                  color: Colors.orange,
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => LostFoundScreen())); },
                ),
                _DrawerTile(
                  icon: Icons.event_outlined,
                  title: AppStrings.get('events', lang),
                  subtitle: lang == 'fr' ? 'Evenements a venir' : 'Upcoming events near you',
                  color: AppTheme.primary,
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => EventsScreen())); },
                ),
                _DrawerTile(
                  icon: Icons.auto_stories_outlined,
                  title: AppStrings.get('stories', lang),
                  subtitle: lang == 'fr' ? 'Animaux qui ont trouve un foyer' : 'Pets that found their home',
                  color: Colors.green,
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => SuccessStoriesScreen())); },
                ),
                _DrawerTile(
                  icon: Icons.favorite_outline,
                  title: AppStrings.get('donate', lang),
                  subtitle: lang == 'fr' ? 'Soutenez notre mission' : 'Support our mission',
                  color: Colors.red,
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => DonateScreen())); },
                ),
                _DrawerTile(
                  icon: Icons.handshake_outlined,
                  title: AppStrings.get('partners', lang),
                  subtitle: lang == 'fr' ? 'Vets, refuges et ONG' : 'Vets, shelters and NGOs',
                  color: AppTheme.primary,
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => PartnersScreen())); },
                ),
                _DrawerTile(
                  icon: Icons.volunteer_activism_outlined,
                  title: AppStrings.get('volunteer', lang),
                  subtitle: lang == 'fr' ? 'Rejoignez notre communaute' : 'Join our community',
                  color: Colors.orange,
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => VolunteerScreen())); },
                ),
                _DrawerTile(
                  icon: Icons.info_outline,
                  title: AppStrings.get('about_app', lang),
                  subtitle: lang == 'fr' ? 'Notre histoire et mission' : 'Our story and mission',
                  color: Colors.blue,
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => AboutScreen())); },
                ),
                _DrawerTile(
                  icon: Icons.support_agent_outlined,
                  title: AppStrings.get('contact', lang),
                  subtitle: lang == 'fr' ? 'Obtenir de l aide' : 'Get help from our team',
                  color: Colors.purple,
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => ContactScreen())); },
                ),
                const Divider(height: 32),
                Consumer<LanguageProvider>(
                  builder: (context, langProvider, _) => ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.language, color: Colors.blue, size: 22),
                    ),
                    title: Text(langProvider.lang == 'en' ? 'Switch to French' : 'Passer en Anglais',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textDark)),
                    subtitle: Text(langProvider.lang == 'en' ? 'Langue: English' : 'Language: Francais',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    onTap: () => langProvider.toggleLanguage(),
                  ),
                ),
                _DrawerTile(
                  icon: Icons.logout,
                  title: AppStrings.get('sign_out', lang),
                  subtitle: '',
                  color: Colors.grey,
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    if (!context.mounted) return;
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Powered by JCI Grand Baie',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textDark)),
      subtitle: subtitle.isNotEmpty ? Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}