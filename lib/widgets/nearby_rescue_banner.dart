import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../lang/app_strings.dart';
import '../providers/language_provider.dart';
import '../providers/rescue_alerts_provider.dart';
import '../screens/rescue/rescue_list_screen.dart';

/// Text for the banner: "1 rescue request near you" / "3 rescue requests
/// near you".
String nearbyRescueBannerText(int count, String lang) => count == 1
    ? AppStrings.get('ra_banner_one', lang)
    : AppStrings.get('ra_banner_many', lang).replaceAll('{n}', '$count');

/// Strip shown on the home screen to a volunteer/rescuer when there are open
/// rescue requests in their area they have not looked at yet. Takes no space
/// otherwise.
class NearbyRescueBanner extends StatelessWidget {
  const NearbyRescueBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.watch<RescueAlertsProvider?>()?.unseenCount ?? 0;
    if (count == 0) return const SizedBox.shrink();
    final lang = context.watch<LanguageProvider>().lang;

    return Material(
      color: Colors.red.shade700,
      child: InkWell(
        key: const ValueKey('nearby-rescue-banner'),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RescueListScreen())),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                nearbyRescueBannerText(count, lang),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              AppStrings.get('ra_view', lang),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const Icon(Icons.chevron_right, color: Colors.white, size: 20),
          ]),
        ),
      ),
    );
  }
}
