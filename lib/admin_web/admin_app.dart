import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/adoption.dart';
import '../theme/app_theme.dart';
import '../utils/geo_utils.dart';
import '../widgets/app_image.dart';
import '../widgets/location_picker.dart';
import 'admin_manage.dart';
import 'audit.dart';
import 'detail_panel.dart';
import 'audit_log_page.dart';
import 'collection_table.dart';
import 'overview.dart';
import 'reports_section.dart';

import 'session_timeout.dart';

const _adminRoles = ['admin', 'superAdmin'];
const _allRoles = ['adopter', 'rehomer', 'volunteer', 'partner', 'admin', 'superAdmin'];

class AdminWebApp extends StatelessWidget {
  const AdminWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MauZanimo Admin',
      debugShowCheckedModeBanner: false,
      theme: _adminTheme(),
      home: const _AuthGate(),
    );
  }
}

/// Signs the admin in and checks their role in Firestore. The UI check is
/// only a convenience - Firestore rules are what actually enforce access.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snap.data;
        if (user == null) return const _SignInPage();
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, roleSnap) {
            if (!roleSnap.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            final role = roleSnap.data!.data()?['role'] as String? ?? 'adopter';
            if (!_adminRoles.contains(role)) {
              return Scaffold(
                body: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.lock_outline, size: 48),
                    const SizedBox(height: 12),
                    Text('${user.email} is not an administrator.'),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: FirebaseAuth.instance.signOut, child: const Text('Sign out')),
                  ]),
                ),
              );
            }
            return IdleSignOut(child: AdminShell(user: user, role: role));
          },
        );
      },
    );
  }
}

class _SignInPage extends StatefulWidget {
  const _SignInPage();
  @override
  State<_SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<_SignInPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;

  Future<void> _run(Future<void> Function() op) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await op();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? e.code);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: AutofillGroup(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Icon(Icons.pets, size: 40, color: AppTheme.primary),
                  const SizedBox(height: 8),
                  Text('MauZanimo Admin', textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _email,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                    onSubmitted: (_) => _run(() => FirebaseAuth.instance
                        .signInWithEmailAndPassword(email: _email.text.trim(), password: _password.text)),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _run(() => FirebaseAuth.instance
                            .signInWithEmailAndPassword(email: _email.text.trim(), password: _password.text)),
                    child: const Text('Sign in'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _run(() => FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider())),
                    icon: const Icon(Icons.login),
                    label: const Text('Sign in with Google'),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Section {
  final String label;
  final IconData icon;
  final Widget Function() build;

  /// Items needing attention in this section, shown as a sidebar badge.
  final Query<Map<String, dynamic>>? todo;
  const _Section(this.label, this.icon, this.build, {this.todo});
}

final _fs = FirebaseFirestore.instance;

class AdminShell extends StatefulWidget {
  final User user;
  final String role;
  const AdminShell({super.key, required this.user, required this.role});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  bool get _isSuper => widget.role == 'superAdmin';

  late final List<_Section> _sections = [
    _Section('Overview', Icons.dashboard_outlined, () => AdminOverview(onOpen: _openSection, footer: _mapFooter())),
    _Section('Reports', Icons.flag_outlined, () => const AdminReportsSection(),
        todo: _fs.collection('reports').where('status', isEqualTo: 'open')),
    _Section('Sightings', Icons.add_location_alt_outlined, () => const _SightingsPage()),
    _Section('Pets', Icons.pets, _pets),
    _Section('Adoptions', Icons.favorite_outline, _adoptions,
        todo: _fs.collection('adoptions').where('currentStage', isEqualTo: 'application')),
    _Section('Inquiries', Icons.mail_outline, _inquiries,
        todo: _fs.collection('inquiries').where('status', isEqualTo: 'pending')),
    _Section('Lost & Found', Icons.search, _lostFound),
    _Section('Rescue SOS', Icons.warning_amber_rounded, _rescue,
        todo: _fs.collection('rescue_reports').where('status', isEqualTo: 'pending')),
    _Section('Fosters', Icons.home_outlined, _fosters,
        todo: _fs.collection('fosters').where('status', isEqualTo: 'pending')),
    _Section('Events', Icons.event, _events),
    _Section('Stories', Icons.auto_stories_outlined, _stories),
    _Section('Volunteers', Icons.volunteer_activism_outlined, _volunteers),
    _Section('Users', Icons.people_outline, _users),
    _Section('Audit log', Icons.history, () => const AuditLogPage()),
  ];

  /// Navigates to the section with this label (used by the Overview page).
  void _openSection(String label) {
    final i = _sections.indexWhere((s) => s.label == label);
    if (i >= 0) setState(() => _index = i);
  }

  Widget _mapFooter() => Builder(
        builder: (context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Last 7 days on the map', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const SizedBox(height: 460, child: _ActivityMap()),
        ]),
      );

  Widget _pets() => CollectionTable(
        title: 'Pets',
        collection: 'pets',
        onOpen: (context, doc) => showPetPanel(context, doc.id, isSuper: _isSuper),
        columns: [
          Col('Photo', _imageOf, image: true),
          Col('Name', _f('name')),
          Col('Visibility', (d) => d['hidden'] == true ? 'hidden' : 'visible',
              cell: (d) => d['hidden'] == true ? const StatusPill('hidden') : const Text('Visible')),
          Col('Type', _f('type')),
          Col('Age', _f('age')),
          Col('Location', _f('location')),
          Col('Contact', _f('contact')),
          Col('Uploaded by (uid)', _f('uploadedBy')),
          Col('Created', _f('createdAt')),
        ],
        status: StatusCol(
          label: 'Status',
          field: 'status',
          options: ['available', 'pending', 'adopted'],
          fallback: 'available',
        ),
      );

  Widget _adoptions() => CollectionTable(
        title: 'Adoptions',
        collection: 'adoptions',
        onOpen: (context, doc) => showAdoptionPanel(context, doc.id, isSuper: _isSuper),
        columns: [
          Col('Photo', (d) => null, cell: (d) => PetThumb(d['petId'] as String?)),
          Col('Pet', _f('petName')),
          Col('Adopter', _f('adopterName')),
          Col('Email', _f('adopterEmail')),
          Col('Phone', _f('adopterPhone')),
          Col('Applied', _f('createdAt')),
          Col('Meet & greet', _f('meetGreetAt')),
          Col('Rejection reason', _f('rejectionReason')),
        ],
        extraActions: (doc) => [
          IconButton(
            tooltip: 'View pet post',
            icon: const Icon(Icons.pets),
            onPressed: (doc.data()['petId'] as String? ?? '').isEmpty
                ? null
                : () => showPetPanel(context, doc.data()['petId'] as String, isSuper: _isSuper),
          ),
        ],
        status: StatusCol(
          label: 'Stage',
          field: 'currentStage',
          options: AdoptionStage.values.map((s) => s.name).toList(),
          fallback: 'application',
          // Rejections need a reason, so they go through the detail panel.
          isLocked: (s) => s == 'rejected',
          // Records history, syncs the pet's status and notifies the adopter.
          // (The stage change itself is also logged by CollectionTable.)
          onChange: (doc, value) => setAdoptionStage(doc.reference, doc.data(), value, logStage: false),
        ),
      );

  Widget _inquiries() => CollectionTable(
        title: 'Adoption inquiries',
        collection: 'inquiries',
        columns: [
          Col('Pet', _f('petName')),
          Col('Applicant', _f('applicantName')),
          Col('Email', _f('email')),
          Col('Phone', _f('phone')),
          Col('Message', _f('message'), width: 320),
          Col('Received', _f('createdAt')),
        ],
        status: const StatusCol(
          label: 'Status',
          field: 'status',
          options: ['pending', 'contacted', 'approved', 'rejected'],
          fallback: 'pending',
        ),
        extraActions: (doc) => [
          IconButton(
            tooltip: 'View pet post',
            icon: const Icon(Icons.pets),
            onPressed: (doc.data()['petId'] as String? ?? '').isEmpty
                ? null
                : () => showPetPanel(context, doc.data()['petId'] as String, isSuper: _isSuper),
          ),
          IconButton(
            tooltip: 'Email applicant',
            icon: const Icon(Icons.email_outlined),
            onPressed: () => launchUrl(Uri(
              scheme: 'mailto',
              path: doc.data()['email'] as String? ?? '',
              queryParameters: {'subject': 'Your MauZanimo adoption inquiry for ${doc.data()['petName'] ?? ''}'},
            )),
          ),
        ],
      );

  Widget _lostFound() => CollectionTable(
        title: 'Lost & Found',
        collection: 'lostfound',
        columns: [
          Col('Photo', _imageOf, image: true),
          Col('Type', _f('type')),
          Col('Animal', _f('animalType')),
          Col('Description', _f('description'), width: 320),
          Col('Location', _f('location')),
          Col('GPS', _f('geo')),
          Col('Contact', _f('contact')),
          Col('Posted', _f('createdAt')),
        ],
      );

  Widget _rescue() => CollectionTable(
        title: 'Rescue SOS reports',
        collection: 'rescue_reports',
        columns: [
          Col('Urgency', _f('urgency')),
          Col('Animal', _f('animalType')),
          Col('Description', _f('description'), width: 320),
          Col('Location', _f('location')),
          Col('Reporter', _f('reporterName')),
          Col('Phone', _f('reporterPhone')),
          Col('Volunteer', _f('assignedVolunteerName')),
          Col('Reported', _f('createdAt')),
        ],
        status: StatusCol(
          label: 'Status',
          field: 'status',
          options: ['pending', 'assigned', 'resolved'],
          fallback: 'pending',
        ),
      );

  Widget _fosters() => CollectionTable(
        title: 'Foster applications',
        collection: 'fosters',
        columns: [
          Col('Pet', _f('petName')),
          Col('Foster', _f('fosterUserName')),
          Col('Notes', _f('notes'), width: 320),
          Col('Start', _f('startDate')),
          Col('End', _f('endDate')),
        ],
        status: StatusCol(
          label: 'Status',
          field: 'status',
          options: ['pending', 'active', 'completed', 'cancelled'],
          fallback: 'pending',
        ),
      );

  Widget _events() => CollectionTable(
        title: 'Events',
        collection: 'events',
        orderBy: null,
        columns: [
          Col('Photo', _imageOf, image: true),
          Col('Title', _f('title')),
          Col('Date', _f('date')),
          Col('Time', _f('time')),
          Col('Location', _f('location')),
          Col('Description', _f('description'), width: 320),
        ],
        header: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () => _eventDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('New event'),
            ),
          ),
        ),
      );

  Widget _stories() => CollectionTable(
        title: 'Success stories',
        collection: 'stories',
        columns: [
          Col('Photo', _imageOf, image: true),
          Col('Pet', _f('petName')),
          Col('Adopter', _f('adopterName')),
          Col('Story', _f('story'), width: 400),
          Col('Posted', _f('createdAt')),
        ],
      );

  Widget _volunteers() => CollectionTable(
        title: 'Volunteer sign-ups',
        collection: 'volunteers',
        columns: [
          Col('Name', _f('name')),
          Col('Email', _f('email')),
          Col('Phone', _f('phone')),
          Col('Message', _f('message'), width: 360),
          Col('Signed up', _f('createdAt')),
        ],
      );

  Widget _users() => CollectionTable(
        title: 'Users',
        collection: 'users',
        orderBy: null, // older Google sign-ins may have no createdAt
        allowDelete: _isSuper,
        onOpen: (context, doc) => showUserPanel(context, doc.id, isSuper: _isSuper),
        columns: [
          Col('Name', _f('name')),
          Col('Email', _f('email')),
          Col('Phone', _f('phone')),
          Col('Verification', _f('verificationLevel')),
          Col('Joined', _f('createdAt')),
        ],
        status: StatusCol(
          label: 'Role',
          field: 'role',
          options: _allRoles,
          fallback: 'adopter',
          // Mirrors firestore.rules: only a superAdmin can grant admin roles.
          isLocked: (role) => !_isSuper && _adminRoles.contains(role),
        ),
      );

  Future<void> _eventDialog(BuildContext context) async {
    final title = TextEditingController();
    final date = TextEditingController();
    final time = TextEditingController();
    final location = TextEditingController();
    final description = TextEditingController();
    final imageUrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('New event'),
        content: SizedBox(
          width: 420,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final (label, ctl) in [
              ('Title', title),
              ('Date (e.g. 2026-12-12)', date),
              ('Time (e.g. 09:00 - 13:00)', time),
              ('Location', location),
              ('Image URL (optional)', imageUrl),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(controller: ctl, decoration: InputDecoration(labelText: label)),
              ),
            TextField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Create')),
        ],
      ),
    );
    if (ok != true || title.text.trim().isEmpty) return;
    final ref = await FirebaseFirestore.instance.collection('events').add({
      'title': title.text.trim(),
      'date': date.text.trim(),
      'time': time.text.trim(),
      'location': location.text.trim(),
      'description': description.text.trim(),
      'imageUrl': imageUrl.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    unawaited(logAdminAction(action: 'create', collection: 'events', docId: ref.id, summary: title.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final rail = NavigationRail(
      extended: wide,
      selectedIndex: _index,
      onDestinationSelected: (i) => setState(() => _index = i),
      leading: Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 12),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.pets, color: AppTheme.textDark, size: 22),
          ),
          if (wide) ...[
            const SizedBox(width: 10),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('MauZanimo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
              Text('Admin', style: TextStyle(fontSize: 11, color: AppTheme.accent, letterSpacing: 1.2)),
            ]),
          ],
        ]),
      ),
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primary,
                child: Text((widget.user.email ?? '?')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              if (wide) ...[
                const SizedBox(height: 6),
                Text(widget.user.email ?? '',
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(widget.role, style: const TextStyle(fontSize: 11, color: AppTheme.accent)),
                ),
              ],
              IconButton(
                tooltip: 'Sign out',
                color: Colors.white70,
                icon: const Icon(Icons.logout),
                onPressed: FirebaseAuth.instance.signOut,
              ),
            ]),
          ),
        ),
      ),
      destinations: [
        for (final s in _sections)
          NavigationRailDestination(
            icon: _NavBadge(query: s.todo, icon: Icon(s.icon)),
            label: Text(s.label),
          ),
      ],
    );
    return Scaffold(
      body: Row(children: [
        Container(
          color: AppTheme.textDark,
          child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).height),
            child: IntrinsicHeight(child: rail),
          ),
          ),
        ),
        // KeyedSubtree so each section gets fresh state (and its own stream).
        Expanded(child: KeyedSubtree(key: ValueKey(_index), child: _sections[_index].build())),
      ]),
    );
  }
}

/// MauZanimo brand look for the admin: teal primary, gold accent, soft
/// grey canvas with white rounded cards.
ThemeData _adminTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppTheme.primary,
    primary: AppTheme.primary,
    secondary: AppTheme.accent,
    surface: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    visualDensity: VisualDensity.compact,
    scaffoldBackgroundColor: const Color(0xFFF5F7F7),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppTheme.textDark,
      indicatorColor: AppTheme.primary,
      selectedIconTheme: const IconThemeData(color: Colors.white),
      unselectedIconTheme: IconThemeData(color: Colors.white.withValues(alpha: 0.7)),
      selectedLabelTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      unselectedLabelTextStyle: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
    ),
    inputDecorationTheme: const InputDecorationTheme(filled: true, fillColor: Colors.white),
    chipTheme: ChipThemeData(backgroundColor: AppTheme.primary.withValues(alpha: 0.08), side: BorderSide.none),
  );
}

/// Live count of items needing attention, shown as a badge in the sidebar.
/// Refreshed every minute with cheap aggregate queries.
class _NavBadge extends StatefulWidget {
  final Query<Map<String, dynamic>>? query;
  final Widget icon;
  const _NavBadge({required this.query, required this.icon});

  @override
  State<_NavBadge> createState() => _NavBadgeState();
}

class _NavBadgeState extends State<_NavBadge> {
  int _count = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.query == null) return;
    _refresh();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _refresh());
  }

  Future<void> _refresh() async {
    try {
      final agg = await widget.query!.count().get();
      if (mounted) setState(() => _count = agg.count ?? 0);
    } catch (_) {/* badge is best-effort */}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Badge(
        isLabelVisible: _count > 0,
        backgroundColor: AppTheme.accent,
        textColor: AppTheme.textDark,
        label: Text(_count > 99 ? '99+' : '$_count'),
        child: widget.icon,
      );
}

Object? Function(Map<String, dynamic>) _f(String field) => (d) => d[field];
Object? _imageOf(Map<String, dynamic> d) => d['imageUrl'];


// ---------------------------------------------------------------------------
// Activity map (shown under the Overview dashboard)
// ---------------------------------------------------------------------------

/// Sightings and geotagged lost & found posts from the last week.
class _ActivityMap extends StatelessWidget {
  const _ActivityMap();

  @override
  Widget build(BuildContext context) {
    final since = Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7)));
    final db = FirebaseFirestore.instance;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.collection('sightings').where('createdAt', isGreaterThan: since).snapshots(),
      builder: (context, sightings) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db.collection('lostfound').where('createdAt', isGreaterThan: since).snapshots(),
        builder: (context, lost) {
          final markers = <Marker>[
            for (final d in sightings.data?.docs ?? const [])
              if (d.data()['geo'] is GeoPoint)
                _marker(context, d.data(), d.data()['geo'] as GeoPoint, Colors.teal, 'Sighting'),
            for (final d in lost.data?.docs ?? const [])
              if (d.data()['geo'] is GeoPoint)
                _marker(context, d.data(), d.data()['geo'] as GeoPoint,
                    d.data()['type'] == 'Found' ? Colors.green : Colors.red, d.data()['type'] as String? ?? 'Lost'),
          ];
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(children: [
              FlutterMap(
                options: const MapOptions(initialCenter: LatLng(mauritiusLat, mauritiusLng), initialZoom: 10),
                children: [osmTileLayer(), MarkerLayer(markers: markers)],
              ),
              osmAttribution(),
              Positioned(
                left: 8,
                top: 8,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                      _Legend(Colors.teal, 'Sighting'),
                      _Legend(Colors.red, 'Lost'),
                      _Legend(Colors.green, 'Found'),
                    ]),
                  ),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }

  Marker _marker(BuildContext context, Map<String, dynamic> d, GeoPoint g, Color color, String kind) => Marker(
        point: LatLng(g.latitude, g.longitude),
        width: 36,
        height: 36,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: () => _showRecord(context, kind, d, g),
          child: Icon(Icons.location_pin, color: color, size: 36),
        ),
      );
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend(this.color, this.label);
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.location_pin, color: color, size: 16),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ]);
}

void _showRecord(BuildContext context, String kind, Map<String, dynamic> d, GeoPoint g) {
  final created = d['createdAt'];
  showDialog(
    context: context,
    builder: (c) => AlertDialog(
      title: Text('$kind · ${d['animalType'] ?? ''}'),
      content: SizedBox(
        width: 420,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AppImage(d['imageUrl'] as String?, height: 240, width: double.infinity, decodeWidth: 420),
          ),
          const SizedBox(height: 8),
          if (created is Timestamp) Text(DateFormat('EEE d MMM yyyy, HH:mm').format(created.toDate())),
          Text(d['description'] as String? ?? ''),
          const SizedBox(height: 4),
          SelectableText(
            '${d['locationLabel'] ?? d['location'] ?? ''}  ${formatLatLng(g.latitude, g.longitude)}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=${g.latitude},${g.longitude}')),
          child: const Text('Open in Google Maps'),
        ),
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close')),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Sightings: map + moderation table
// ---------------------------------------------------------------------------

class _SightingsPage extends StatelessWidget {
  const _SightingsPage();

  @override
  Widget build(BuildContext context) {
    return CollectionTable(
      title: 'Sightings',
      collection: 'sightings',
      columns: [
        Col('Photo', _imageOf, image: true),
        Col('Animal', _f('animalType')),
        Col('Description', _f('description'), width: 300),
        Col('Place', _f('locationLabel')),
        Col('GPS', _f('geo')),
        Col('± m', _f('accuracyMeters')),
        Col('Lost report', _f('lostReportId')),
        Col('Reporter', _f('reporterName')),
        Col('Reported', _f('createdAt')),
      ],
      status: const StatusCol(
        label: 'Status',
        field: 'status',
        options: ['open', 'resolved', 'hidden'],
        fallback: 'open',
      ),
      extraActions: (doc) => [
        IconButton(
          tooltip: 'View',
          icon: const Icon(Icons.map_outlined),
          onPressed: () {
            final g = doc.data()['geo'];
            if (g is GeoPoint) _showRecord(context, 'Sighting', doc.data(), g);
          },
        ),
      ],
    );
  }
}
