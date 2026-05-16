import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';
import 'package:stray_pets_mu/screens/auth/login_screen.dart';
import 'package:stray_pets_mu/screens/pets/my_pets_screen.dart';
import 'package:stray_pets_mu/providers/auth_provider.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/providers/gamification_provider.dart';
import 'package:stray_pets_mu/providers/pet_provider.dart';
import 'package:stray_pets_mu/models/pet_preferences.dart';
import 'package:stray_pets_mu/models/user_gamification.dart';
import 'package:stray_pets_mu/widgets/gamification/impact_ring.dart';
import 'package:stray_pets_mu/widgets/gamification/tier_badge.dart';
import 'package:stray_pets_mu/widgets/verification_badge_widget.dart';
import 'package:stray_pets_mu/models/verification_badge.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final lang = context.watch<LanguageProvider>().lang;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Column(children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    child: const Icon(Icons.person, size: 48, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 12),
                  Builder(builder: (context) {
                    final profile = authProvider.userProfile;
                    final phone = profile?.phone;
                    return Column(children: [
                      Text(authProvider.displayName,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                      const SizedBox(height: 4),
                      Text(authProvider.email ?? '',
                        style: TextStyle(fontSize: 14, color: AppTheme.textDark.withOpacity(0.6))),
                      if (phone != null && phone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(phone,
                          style: TextStyle(fontSize: 14, color: AppTheme.textDark.withOpacity(0.6))),
                      ],
                      const SizedBox(height: 8),
                      VerificationBadgeWidget(
                        level: profile?.verificationLevel ?? VerificationLevel.none,
                        size: 14,
                      ),
                    ]);
                  }),
                ]),
              ),
              const SizedBox(height: 24),
              // Gamification Section
              Consumer<GamificationProvider>(
                builder: (context, gamificationProvider, _) {
                  final gamification = gamificationProvider.gamification;
                  if (gamification == null) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          gamification.tierColor.withValues(alpha: 0.1),
                          AppTheme.primary.withValues(alpha: 0.05),
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
                        Row(
                          children: [
                            ImpactRing(
                              progress: gamification.tierProgress,
                              points: gamification.totalPoints,
                              pointsToNext: gamification.pointsToNextTier,
                              tierName: gamification.tierDisplayName,
                              tierColor: gamification.tierColor,
                              size: 100,
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TierBadge(
                                    tier: gamification.tier,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '${gamification.totalPoints} Impact Points',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (gamification.tier != MembershipTier.guardian)
                                    Text(
                                      '${gamification.pointsToNextTier} points to ${UserGamification.calculateTier(gamification.totalPoints + gamification.pointsToNextTier).name}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Pet Preferences Card
              if (authProvider.userProfile != null)
                _PreferencesCard(
                  preferences: authProvider.userProfile!.petPreferences,
                  uid: authProvider.uid!,
                  petProvider: context.read<PetProvider>(),
                ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPetsScreen())),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: Row(children: [
                    const Icon(Icons.pets, color: AppTheme.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(AppStrings.get('my_pet_listings', lang), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                      Text(AppStrings.get('edit_or_delete_your_listed_pets', lang), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ])),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  ]),
                ),
              ),
              const SizedBox(height: 32),
              Text(AppStrings.get('my_inquiries', lang),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                  .collection('inquiries')
                  .where('userId', isEqualTo: authProvider.uid)
                  .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Column(children: [
                      Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text(AppStrings.get('no_inquiries_yet', lang), style: const TextStyle(color: Colors.grey)),
                    ]));
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                      final status = data['status'] ?? 'pending';
                      final color = status == 'approved' ? Colors.green : status == 'rejected' ? Colors.red : Colors.orange;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.pets, color: AppTheme.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['petName'] ?? 'Unknown',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                                const SizedBox(height: 4),
                                Text(AppStrings.get('status_label', lang) + status[0].toUpperCase() + status.substring(1),
                                  style: TextStyle(fontSize: 12, color: color)),
                              ],
                            )),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 32),
              // Reviews Section
              if (authProvider.userProfile != null) ...[
                Text(AppStrings.get('reviews', lang),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('reviews')
                      .where('targetUserId', isEqualTo: authProvider.uid)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(AppStrings.get('no_reviews', lang),
                              style: const TextStyle(color: Colors.grey)),
                        ),
                      );
                    }
                    final reviews = snapshot.data!.docs;
                    final avgRating = reviews.fold<double>(
                        0, (sum, d) => sum + ((d.data() as Map<String, dynamic>)['rating'] as num?)!.toInt()) / reviews.length;
                    return Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star, color: AppTheme.accent, size: 20),
                            const SizedBox(width: 4),
                            Text(avgRating.toStringAsFixed(1),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark)),
                            const SizedBox(width: 8),
                            Text('(${reviews.length} ${AppStrings.get('reviews', lang)})',
                                style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...reviews.take(5).map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Text(data['reviewerName'] ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const Spacer(),
                                  ...List.generate(5, (i) => Icon(
                                    i < (data['rating'] as num?)!.toInt() ? Icons.star : Icons.star_border,
                                    size: 14, color: AppTheme.accent)),
                                ]),
                                if (data['comment'] != null) ...[
                                  const SizedBox(height: 4),
                                  Text(data['comment'] as String,
                                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await authProvider.signOut();
                    if (!context.mounted) return;
                    Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()));
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: Text(AppStrings.get('sign_out', lang), style: const TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreferencesCard extends StatefulWidget {
  final PetPreferences? preferences;
  final String uid;
  final PetProvider petProvider;

  const _PreferencesCard({
    required this.preferences,
    required this.uid,
    required this.petProvider,
  });

  @override
  State<_PreferencesCard> createState() => _PreferencesCardState();
}

class _PreferencesCardState extends State<_PreferencesCard> {
  late List<String> _selectedTypes;
  late String _ageRange;
  late String _gender;
  late TextEditingController _locationController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedTypes = List.from(widget.preferences?.types ?? []);
    _ageRange = widget.preferences?.ageRange ?? 'any';
    _gender = widget.preferences?.gender ?? 'any';
    _locationController = TextEditingController(text: widget.preferences?.preferredLocation ?? '');
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final prefs = PetPreferences(
      types: _selectedTypes,
      ageRange: _ageRange,
      preferredLocation: _locationController.text.isNotEmpty ? _locationController.text : null,
      gender: _gender,
    );
    await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
      'petPreferences': prefs.toMap(),
    });
    widget.petProvider.setPreferences(prefs);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.get('preferences_saved', 'en')), duration: const Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.tune, color: AppTheme.primary, size: 20),
            SizedBox(width: 8),
            Text('Pet Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          ]),
          const SizedBox(height: 12),
          const Text('Type', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, children: ['dog', 'cat', 'other'].map((t) {
            final selected = _selectedTypes.contains(t);
            return FilterChip(
              label: Text(t[0].toUpperCase() + t.substring(1)),
              selected: selected,
              onSelected: (v) {
                setState(() => v ? _selectedTypes.add(t) : _selectedTypes.remove(t));
              },
              selectedColor: AppTheme.primary.withOpacity(0.2),
              checkmarkColor: AppTheme.primary,
            );
          }).toList()),
          const SizedBox(height: 12),
          const Text('Age Range', style: TextStyle(fontSize: 12, color: Colors.grey)),
          DropdownButtonFormField<String>(
            initialValue: _ageRange,
            decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            items: const [
              DropdownMenuItem(value: 'any', child: Text('Any Age')),
              DropdownMenuItem(value: 'young', child: Text('Young (0-1 year)')),
              DropdownMenuItem(value: 'adult', child: Text('Adult (1-7 years)')),
              DropdownMenuItem(value: 'senior', child: Text('Senior (7+ years)')),
            ],
            onChanged: (v) => setState(() => _ageRange = v!),
          ),
          const SizedBox(height: 12),
          const Text('Gender', style: TextStyle(fontSize: 12, color: Colors.grey)),
          DropdownButtonFormField<String>(
            initialValue: _gender,
            decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            items: const [
              DropdownMenuItem(value: 'any', child: Text('Any Gender')),
              DropdownMenuItem(value: 'male', child: Text('Male')),
              DropdownMenuItem(value: 'female', child: Text('Female')),
            ],
            onChanged: (v) => setState(() => _gender = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(labelText: 'Preferred Location', isDense: true, border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save Preferences'),
            ),
          ),
        ],
      ),
    );
  }
}