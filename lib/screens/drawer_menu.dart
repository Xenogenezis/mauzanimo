import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/providers/theme_provider.dart';
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
import 'package:stray_pets_mu/screens/gamification/leaderboard_screen.dart';
import 'package:stray_pets_mu/screens/rescue/rescue_report_screen.dart';
import 'package:stray_pets_mu/screens/rescue/rescue_list_screen.dart';
import 'package:stray_pets_mu/screens/foster/my_fosters_screen.dart';

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
                  subtitle: AppStrings.get('lost_found_subtitle', lang),
                  color: Colors.orange,
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => LostFoundScreen())); },
                ),
                _DrawerTile(
                  icon: Icons.warning_amber_rounded,
                  title: AppStrings.get('emergency_rescue', lang),
                  subtitle: AppStrings.get('report_injured_stray', lang),
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => RescueReportScreen()));
                  },
                ),
                _DrawerTile(
                  icon: Icons.home_outlined,
                  title: AppStrings.get('foster_program', lang),
                  subtitle: AppStrings.get('foster_program_subtitle', lang),
                  color: Colors.teal,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => MyFostersScreen()));
                  },
                ),
                _DrawerTile(
                  icon: Icons.event_outlined,
                  title: AppStrings.get('events', lang),
                  subtitle: AppStrings.get('events_subtitle', lang),
                  color: AppTheme.primary,
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => EventsScreen())); },
                ),
                _DrawerTile(
                  icon: Icons.leaderboard_outlined,
                  title: AppStrings.get('leaderboard', lang),
                  subtitle: AppStrings.get('leaderboard_subtitle', lang),
                  color: Colors.amber,
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => LeaderboardScreen())); },
                ),
                _DrawerTile(
                  icon: Icons.auto_stories_outlined,
                  title: AppStrings.get('stories', lang),
                  subtitle: AppStrings.get('stories_subtitle', lang),
                  color: Colors.green,
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => SuccessStoriesScreen())); },
                ),
                _DrawerTile(
                  icon: Icons.favorite_outline,
                  title: AppStrings.get('donate', lang),
                  subtitle: AppStrings.get('donate_subtitle', lang),
                  color: Colors.red,
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => DonateScreen())); },
                ),
                _DrawerTile(
                  icon: Icons.handshake_outlined,
                  title: AppStrings.get('partners', lang),
                  subtitle: AppStrings.get('partners_subtitle', lang),
                  color: AppTheme.primary,
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => PartnersScreen())); },
                ),
                _DrawerTile(
                  icon: Icons.volunteer_activism_outlined,
                  title: AppStrings.get('volunteer', lang),
                  subtitle: AppStrings.get('volunteer_subtitle', lang),
                  color: Colors.orange,
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => VolunteerScreen())); },
                ),
                _DrawerTile(
                  icon: Icons.info_outline,
                  title: AppStrings.get('about_app', lang),
                  subtitle: AppStrings.get('about_app', lang),
                  color: Colors.blue,
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => AboutScreen())); },
                ),
                _DrawerTile(
                  icon: Icons.support_agent_outlined,
                  title: AppStrings.get('contact', lang),
                  subtitle: AppStrings.get('contact', lang),
                  color: Colors.purple,
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => ContactScreen())); },
                ),
                const Divider(height: 32),
                Consumer<LanguageProvider>(
                  builder: (context, langProvider, _) {
                    final nextLang = langProvider.lang == 'en' ? 'fr' : langProvider.lang == 'fr' ? 'mfe' : 'en';
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.language, color: Colors.blue, size: 22),
                      ),
                      title: Text(AppStrings.get('language', langProvider.lang),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textDark)),
                      subtitle: Text(langProvider.currentLanguageDisplayName,
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                      onTap: () => langProvider.setLanguage(nextLang),
                    );
                  },
                ),
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) => ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(themeProvider.isDark ? Icons.light_mode : Icons.dark_mode, color: Colors.purple, size: 22),
                    ),
                    title: Text(themeProvider.isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textDark)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    onTap: () => themeProvider.toggleTheme(),
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
            child: Text(AppStrings.get('powered_by', lang),
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