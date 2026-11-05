import 'package:stray_pets_mu/widgets/app_image.dart';
import 'package:flutter/material.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/screens/adoption/adoption_workflow_screen.dart';
import 'package:stray_pets_mu/screens/reviews/add_review_screen.dart';
import 'package:stray_pets_mu/screens/foster/foster_application_screen.dart';
import 'package:stray_pets_mu/screens/updates/pet_update_form_screen.dart';
import 'package:stray_pets_mu/widgets/update_timeline.dart';
import 'package:stray_pets_mu/models/pet_update.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stray_pets_mu/widgets/auth_guard.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/providers/recently_viewed_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/screens/pets/adopt_poster_screen.dart';
import 'package:stray_pets_mu/utils/similar_pets.dart';
import 'package:stray_pets_mu/widgets/report_button.dart';

class PetDetailScreen extends StatelessWidget {
  final Map<String, dynamic> pet;
  final String petId;
  const PetDetailScreen({super.key, required this.pet, required this.petId});

  Future<void> _toggleFavourite(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AuthGuard.requireAuth(context, () {});
      return;
    }
    final ref = FirebaseFirestore.instance.collection('favourites');
    final existing = await ref.where('userId', isEqualTo: user.uid).where('petId', isEqualTo: petId).get();
    if (existing.docs.isEmpty) {
      await ref.add({'userId': user.uid, 'petId': petId, 'createdAt': FieldValue.serverTimestamp()});
    } else {
      await existing.docs.first.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _RecordRecentlyViewed(petId: petId, child: Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300, pinned: true,
            actions: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('favourites')
                  .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .where('petId', isEqualTo: petId).snapshots(),
                builder: (context, snapshot) {
                  final isFav = snapshot.data?.docs.isNotEmpty ?? false;
                  return IconButton(
                    icon: Icon(isFav ? Icons.favorite : Icons.favorite_outline,
                      color: isFav ? Colors.red : Colors.white),
                    onPressed: () => _toggleFavourite(context),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  final name = pet['name'] ?? 'this pet';
                  final desc = pet['description'] ?? '';
                  SharePlus.instance.share(ShareParams(
                    text: 'Check out $name on MauZanimo! $desc\n\nDownload the MauZanimo app to adopt pets in Mauritius.',
                    subject: 'Adopt $name - MauZanimo',
                  ));
                },
              ),
              IconButton(
                icon: const Icon(Icons.campaign_outlined, color: Colors.white),
                tooltip: AppStrings.get('pd_poster_action', _langOf(context)),
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AdoptPosterScreen(pet: pet, petId: petId))),
              ),
              if (pet['uploadedBy'] == null ||
                  pet['uploadedBy'] != FirebaseAuth.instance.currentUser?.uid)
                ReportButton(targetCollection: 'pets', targetId: petId, color: Colors.white),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: pet['imageUrl'] != null
                ? _buildImage(pet['imageUrl'])
                : _placeholder(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(pet['name'] ?? 'Unknown',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: _statusColor(pet['status']), borderRadius: BorderRadius.circular(20)),
                        child: Text(pet['status'] ?? 'Available',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(pet['location'] ?? 'Mauritius', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  ]),
                  const SizedBox(height: 20),
                  Row(children: [
                    _chip(Icons.category_outlined, pet['type'] ?? 'Pet'),
                    const SizedBox(width: 10),
                    _chip(Icons.cake_outlined, pet['age'] ?? 'Unknown'),
                    const SizedBox(width: 10),
                    _chip(Icons.male_outlined, pet['gender'] ?? 'Unknown'),
                  ]),
                  const SizedBox(height: 24),
                  const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  const SizedBox(height: 8),
                  Text(pet['description'] ?? 'No description available.',
                    style: TextStyle(fontSize: 14, color: AppTheme.textDark.withOpacity(0.7), height: 1.6)),
                  const SizedBox(height: 24),
                  const Text('Health Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  const SizedBox(height: 8),
                  Row(children: [
                    _healthChip('Vaccinated', pet['vaccinated'] == true),
                    const SizedBox(width: 10),
                    _healthChip('Sterilized', pet['sterilized'] == true),
                      const SizedBox(width: 10),
                    _healthChip('Dewormed', pet['dewormed'] == true),
                      
                  ]),
                  const SizedBox(height: 24),
                  if (pet['adoptionFee'] != null) ...[
                    const Text('Adoption Fee', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rs ${pet['adoptionFee']['total']?.toString() ?? '0'}',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                          const SizedBox(height: 8),
                          if (pet['adoptionFee']['breakdown'] != null)
                            ...(pet['adoptionFee']['breakdown'] as Map<String, dynamic>).entries.map((e) =>
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(e.key, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                    Text('Rs ${e.value}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textDark)),
                                  ],
                                ),
                              ),
                            ),
                          if (pet['adoptionFee']['notes'] != null) ...[
                            const SizedBox(height: 8),
                            Text(pet['adoptionFee']['notes'] as String,
                              style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (pet['status'] == 'adopted') ...[
                    const SizedBox(height: 24),
                    const Text('Photo Updates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                    const SizedBox(height: 12),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('pet_updates')
                          .where('petId', isEqualTo: petId)
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                          final updates = snapshot.data!.docs
                              .map((d) => PetUpdate.fromMap(d.id, d.data() as Map<String, dynamic>))
                              .toList();
                          return Column(children: [
                            UpdateTimeline(updates: updates),
                            const SizedBox(height: 8),
                          ]);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => AuthGuard.requireAuth(context, () {
                          Navigator.push(context,
                            MaterialPageRoute(builder: (_) => PetUpdateFormScreen(petId: petId)));
                        }),
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('Add Update'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: pet['status'] == 'adopted' ? null : () =>
                        AuthGuard.requireAuth(context, () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => AdoptionWorkflowScreen(pet: pet, petId: petId)));
                        }),
                      child: const Text('Start Adoption Process', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final phone = pet['contact'] ?? '';
                        final name = pet['name'] ?? 'this pet';
                        final message = 'Hi, I am interested in adopting ' + name + ' from MauZanimo!';
                        // wa.me only accepts digits; strip anything else from the user-entered contact.
                        var digits = phone.toString().replaceAll(RegExp(r'[^0-9]'), '');
                        if (digits.length == 7 || digits.length == 8) digits = '230$digits'; // local Mauritian number
                        final url = 'https://wa.me/$digits?text=${Uri.encodeComponent(message)}';
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                      label: const Text('Chat on WhatsApp', style: TextStyle(color: Color(0xFF25D366))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF25D366)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  if (pet['uploadedBy'] != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => AuthGuard.requireAuth(context, () {
                          Navigator.push(context,
                            MaterialPageRoute(builder: (_) => AddReviewScreen(
                              targetUserId: pet['uploadedBy'] as String,
                              targetUserName: pet['uploadedByName'] ?? 'User',
                            )));
                        }),
                        icon: const Icon(Icons.star_outline, color: AppTheme.accent),
                        label: const Text('Rate this Rehomer', style: TextStyle(color: AppTheme.accent)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.accent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => AuthGuard.requireAuth(context, () {
                        Navigator.push(context,
                          MaterialPageRoute(builder: (_) => FosterApplicationScreen(
                            petId: petId,
                            petName: pet['name'] ?? '',
                          )));
                      }),
                      icon: const Icon(Icons.home_outlined, color: Colors.teal),
                      label: const Text('Apply to Foster', style: TextStyle(color: Colors.teal)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.teal),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  _SimilarPets(
                    key: ValueKey('similar-$petId'),
                    petId: petId,
                    type: pet['type'] as String?,
                    lang: _langOf(context),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    ));
  }

  /// Current UI language; falls back to English when no provider is above.
  static String _langOf(BuildContext context) {
    try {
      return context.watch<LanguageProvider>().lang;
    } on ProviderNotFoundException {
      return 'en';
    }
  }

  Widget _buildImage(String imageUrl) =>
      AppImage(imageUrl, width: double.infinity, decodeWidth: 800);

  Widget _placeholder() => Container(color: AppTheme.lightGrey,
    child: const Center(child: Icon(Icons.pets, size: 80, color: AppTheme.primary)));
  Widget _chip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: AppTheme.lightGrey, borderRadius: BorderRadius.circular(20)),
    child: Row(children: [Icon(icon, size: 14, color: AppTheme.primary), const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textDark))]));
  Widget _healthChip(String label, bool isTrue) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: isTrue ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20)),
    child: Row(children: [
      Icon(isTrue ? Icons.check_circle_outline : Icons.cancel_outlined,
        size: 14, color: isTrue ? Colors.green : Colors.red),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 12, color: isTrue ? Colors.green : Colors.red))]));
  Color _statusColor(String? s) {
    if (s == 'adopted') return Colors.red;
    if (s == 'pending') return Colors.orange;
    return Colors.green;
  }
}

/// Records the pet as recently viewed once, when the screen is first shown.
class _RecordRecentlyViewed extends StatefulWidget {
  final String petId;
  final Widget child;
  const _RecordRecentlyViewed({required this.petId, required this.child});

  @override
  State<_RecordRecentlyViewed> createState() => _RecordRecentlyViewedState();
}

class _RecordRecentlyViewedState extends State<_RecordRecentlyViewed> {
  @override
  void initState() {
    super.initState();
    try {
      context.read<RecentlyViewedProvider>().record(widget.petId);
    } on ProviderNotFoundException {
      // Not provided (e.g. in isolated widget tests); nothing to record.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// "Similar pets": other available pets of the same type, newest first.
/// Hidden while loading, when there are none, or if the query fails.
class _SimilarPets extends StatefulWidget {
  final String petId;
  final String? type;
  final String lang;
  const _SimilarPets({super.key, required this.petId, required this.type, required this.lang});

  @override
  State<_SimilarPets> createState() => _SimilarPetsState();
}

class _SimilarPetsState extends State<_SimilarPets> {
  late final Future<List<PetDoc>> _future = _load();
  final _scrollController = ScrollController();

  Future<List<PetDoc>> _load() async {
    final type = widget.type;
    if (type == null || type.isEmpty) return const [];
    try {
      // Same shape as PetRepository.getPetsStream (backed by an index).
      final snapshot = await FirebaseFirestore.instance
          .collection('pets')
          .where('type', isEqualTo: type)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
      return filterSimilarPets(
        snapshot.docs.map((d) => (id: d.id, data: d.data())),
        currentPetId: widget.petId,
      );
    } catch (_) {
      return const [];
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PetDoc>>(
      future: _future,
      builder: (context, snapshot) {
        final pets = snapshot.data ?? const <PetDoc>[];
        if (pets.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.get('pd_similar_pets', widget.lang),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const SizedBox(height: 12),
              SizedBox(
                height: 186,
                // Let mouse users drag the row on web/desktop too.
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                    PointerDeviceKind.stylus,
                  }),
                  child: Scrollbar(
                    controller: _scrollController,
                    child: ListView.separated(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(bottom: 10),
                      itemCount: pets.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) => _SimilarPetCard(pet: pets[i]),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SimilarPetCard extends StatelessWidget {
  final PetDoc pet;
  const _SimilarPetCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    final data = pet.data;
    final imageUrl = data['imageUrl'] as String?;
    final location = (data['location'] as String?)?.trim() ?? '';
    return SizedBox(
      width: 140,
      child: Material(
        color: Colors.white,
        elevation: 1,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => PetDetailScreen(pet: data, petId: pet.id))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 110,
                width: double.infinity,
                child: imageUrl != null && imageUrl.trim().isNotEmpty
                    ? AppImage(imageUrl, width: 140, height: 110, decodeWidth: 160)
                    : Container(
                        color: AppTheme.lightGrey,
                        child: Icon(Icons.pets, size: 36,
                          color: AppTheme.primary.withValues(alpha: 0.5))),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                child: Text(
                  (data['name'] as String?)?.trim().isNotEmpty == true ? data['name'] as String : 'Unknown',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
              ),
              if (location.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 2, 10, 0),
                  child: Row(children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: Colors.grey),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                  ]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
