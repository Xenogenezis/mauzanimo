// Overview dashboard: the default page of the web admin panel.
//
// Every number is loaded independently, so a query denied by the rules (or a
// missing index) only blanks its own tile. Only count() aggregates and
// single-field filters are used, which Firestore serves from its automatic
// single-field indexes - no firestore.indexes.json entries are needed.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import 'overview_stats.dart';
import 'overview_widgets.dart';

/// Adoption stages that still need work (everything but completed/rejected).
const _openStages = [
  ('Application', 'application'),
  ('Screening', 'screening'),
  ('Meet & greet', 'meet_greet'),
  ('Trial', 'trial'),
];

/// Upper bound on documents fetched for client-side bucketing / lists.
const _fetchLimit = 2000;

class AdminOverview extends StatefulWidget {
  /// Opens the admin section with this label (e.g. 'Adoptions').
  final ValueChanged<String> onOpen;

  /// Extra content below the dashboard (e.g. the activity map).
  final Widget? footer;

  const AdminOverview({super.key, required this.onOpen, this.footer});

  @override
  State<AdminOverview> createState() => _AdminOverviewState();
}

class _AdminOverviewState extends State<AdminOverview> {
  // Bumped by Refresh; used as a key so every loader starts again.
  int _generation = 0;
  DateTime _loadedAt = DateTime.now();

  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  void _refresh() => setState(() {
        _generation++;
        _loadedAt = DateTime.now();
      });

  List<_KpiSpec> get _kpis {
    final pets = _db.collection('pets');
    final adoptions = _db.collection('adoptions');
    final lost = _db.collection('lostfound');
    final rescue = _db.collection('rescue_reports');
    return [
      _KpiSpec('Pets', Icons.pets, AppTheme.primary, 'Pets', total: pets, parts: [
        for (final s in ['available', 'pending', 'adopted'])
          (s[0].toUpperCase() + s.substring(1), pets.where('status', isEqualTo: s)),
      ]),
      _KpiSpec('Open adoptions', Icons.favorite, Colors.pink, 'Adoptions', parts: [
        for (final (label, stage) in _openStages) (label, adoptions.where('currentStage', isEqualTo: stage)),
      ]),
      _KpiSpec('Lost & found posts', Icons.search, Colors.orange, 'Lost & Found', total: lost, parts: [
        ('Lost', lost.where('type', isEqualTo: 'Lost')),
        ('Found', lost.where('type', isEqualTo: 'Found')),
      ]),
      _KpiSpec('Open sightings', Icons.add_location_alt, Colors.teal, 'Sightings',
          total: _db.collection('sightings').where('status', isEqualTo: 'open')),
      _KpiSpec('Unresolved rescue reports', Icons.warning_amber_rounded, Colors.red, 'Rescue SOS', parts: [
        ('Pending', rescue.where('status', isEqualTo: 'pending')),
        ('Assigned', rescue.where('status', isEqualTo: 'assigned')),
      ]),
      _KpiSpec('New inquiries', Icons.mail, Colors.indigo, 'Inquiries',
          total: _db.collection('inquiries').where('status', isEqualTo: 'pending')),
      _KpiSpec('Pending fosters', Icons.home, Colors.brown, 'Fosters',
          total: _db.collection('fosters').where('status', isEqualTo: 'pending')),
      _KpiSpec('Registered users', Icons.people, Colors.blueGrey, 'Users', total: _db.collection('users')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final now = _loadedAt;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Overview', style: text.headlineSmall),
            Text('Updated ${DateFormat('HH:mm').format(_loadedAt)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            OutlinedButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh), label: const Text('Refresh')),
          ],
        ),
        const SizedBox(height: 16),
        KeyedSubtree(
          key: ValueKey(_generation),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ResponsiveTileGrid(children: [
              for (final k in _kpis) _KpiCard(spec: k, onOpen: () => widget.onOpen(k.section)),
            ]),
            const SizedBox(height: 28),
            Text('Last 30 days', style: text.titleMedium),
            const SizedBox(height: 8),
            ResponsiveTileGrid(maxColumns: 3, children: [
              _ActivityCard(title: 'New pets per week', collection: 'pets', color: AppTheme.primary, now: now),
              _ActivityCard(title: 'Lost & found posts per week', collection: 'lostfound', color: Colors.orange, now: now),
              _ActivityCard(title: 'Adoption requests per week', collection: 'adoptions', color: Colors.pink, now: now),
            ]),
            const SizedBox(height: 28),
            Text('Needs attention', style: text.titleMedium),
            const SizedBox(height: 8),
            ResponsiveTileGrid(maxColumns: 3, children: [
              _AttentionLoader(
                title: 'Unresolved rescue reports',
                icon: Icons.warning_amber_rounded,
                color: Colors.red,
                section: 'Rescue SOS',
                onOpen: widget.onOpen,
                load: () => _rescueRows(now),
              ),
              _AttentionLoader(
                title: 'Adoptions in Application > 3 days',
                icon: Icons.favorite_outline,
                color: Colors.pink,
                section: 'Adoptions',
                onOpen: widget.onOpen,
                load: () => _staleAdoptionRows(now),
              ),
              _AttentionLoader(
                title: 'Inquiries unanswered > 3 days',
                icon: Icons.mail_outline,
                color: Colors.indigo,
                section: 'Inquiries',
                onOpen: widget.onOpen,
                load: () => _staleInquiryRows(now),
              ),
            ]),
          ]),
        ),
        if (widget.footer != null) ...[
          const SizedBox(height: 28),
          widget.footer!,
        ],
      ],
    );
  }

  static Future<List<AttentionRow>> _rescueRows(DateTime now) async {
    final col = _db.collection('rescue_reports');
    final snaps = await Future.wait([
      col.where('status', isEqualTo: 'pending').limit(_fetchLimit).get(),
      col.where('status', isEqualTo: 'assigned').limit(_fetchLimit).get(),
    ]);
    final docs = [for (final s in snaps) ...s.docs.map((d) => d.data())]..sort(compareRescue);
    return [
      for (final d in docs)
        AttentionRow(
          title: '${d['animalType'] ?? 'Animal'} · ${d['location'] ?? d['locationLabel'] ?? 'unknown location'}',
          subtitle: [
            d['status'] ?? 'pending',
            if (asDateTime(d['createdAt']) case final t?) '${formatAge(now.difference(t))} ago',
            if (d['assignedVolunteerName'] case final String v when v.isNotEmpty) v,
          ].join(' · '),
          badge: d['urgency'] as String? ?? 'medium',
          badgeColor: switch (d['urgency']) {
            'critical' => Colors.red,
            'high' => Colors.orange,
            _ => Colors.amber.shade800,
          },
        ),
    ];
  }

  static Future<List<AttentionRow>> _staleAdoptionRows(DateTime now) async {
    final snap = await _db.collection('adoptions').where('currentStage', isEqualTo: 'application').limit(_fetchLimit).get();
    final stale = waitingLongerThan(
      snap.docs.map((d) => d.data()),
      since: stageEnteredAt,
      now: now,
      threshold: const Duration(days: 3),
    );
    return [
      for (final w in stale)
        AttentionRow(
          title: '${w.item['petName'] ?? 'Pet'} — ${w.item['adopterName'] ?? 'adopter'}',
          subtitle: w.item['adopterEmail'] as String? ?? '',
          badge: formatAge(w.waited),
        ),
    ];
  }

  static Future<List<AttentionRow>> _staleInquiryRows(DateTime now) async {
    final snap = await _db.collection('inquiries').where('status', isEqualTo: 'pending').limit(_fetchLimit).get();
    final stale = waitingLongerThan(
      snap.docs.map((d) => d.data()),
      since: (d) => asDateTime(d['createdAt']),
      now: now,
      threshold: const Duration(days: 3),
    );
    return [
      for (final w in stale)
        AttentionRow(
          title: '${w.item['petName'] ?? 'Pet'} — ${w.item['applicantName'] ?? 'applicant'}',
          subtitle: w.item['email'] as String? ?? '',
          badge: formatAge(w.waited),
        ),
    ];
  }
}

// ---------------------------------------------------------------------------
// KPI tiles
// ---------------------------------------------------------------------------

class _KpiSpec {
  final String label;
  final IconData icon;
  final Color color;

  /// Admin section opened when the tile is tapped.
  final String section;

  /// Headline count. When null, the headline is the sum of [parts].
  final Query? total;
  final List<(String, Query)> parts;

  const _KpiSpec(this.label, this.icon, this.color, this.section, {this.total, this.parts = const []});
}

class _KpiCard extends StatefulWidget {
  final _KpiSpec spec;
  final VoidCallback onOpen;
  const _KpiCard({required this.spec, required this.onOpen});

  @override
  State<_KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<_KpiCard> {
  AsyncSnapshot<int> _total = const AsyncSnapshot.waiting();
  late final List<AsyncSnapshot<int>> _parts =
      List.filled(widget.spec.parts.length, const AsyncSnapshot.waiting());

  @override
  void initState() {
    super.initState();
    final total = widget.spec.total;
    if (total != null) _count(total, (v) => _total = v);
    for (var i = 0; i < widget.spec.parts.length; i++) {
      _count(widget.spec.parts[i].$2, (v) => _parts[i] = v);
    }
  }

  // count() aggregation: billed as 1 read per 1000 index entries, not per doc.
  Future<void> _count(Query q, void Function(AsyncSnapshot<int>) assign) async {
    AsyncSnapshot<int> result;
    try {
      final snap = await q.count().get();
      result = AsyncSnapshot.withData(ConnectionState.done, snap.count ?? 0);
    } catch (e, st) {
      result = AsyncSnapshot.withError(ConnectionState.done, e, st);
    }
    if (mounted) setState(() => assign(result));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.spec;
    return KpiTile(
      label: s.label,
      icon: s.icon,
      color: s.color,
      value: s.total != null ? _total : sumCounts(_parts),
      breakdown: [for (var i = 0; i < s.parts.length; i++) (s.parts[i].$1, _parts[i])],
      onTap: widget.onOpen,
    );
  }
}

// ---------------------------------------------------------------------------
// Weekly activity
// ---------------------------------------------------------------------------

class _ActivityCard extends StatefulWidget {
  final String title;
  final String collection;
  final Color color;
  final DateTime now;
  const _ActivityCard({required this.title, required this.collection, required this.color, required this.now});

  @override
  State<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<_ActivityCard> {
  AsyncSnapshot<List<WeekBucket>> _buckets = const AsyncSnapshot.waiting();
  bool _capped = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final since = widget.now.subtract(const Duration(days: 30));
    try {
      // Single-field range filter: served by the automatic createdAt index.
      final snap = await FirebaseFirestore.instance
          .collection(widget.collection)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
          .limit(_fetchLimit)
          .get();
      final buckets = bucketByWeek(snap.docs.map((d) => asDateTime(d.data()['createdAt'])), now: widget.now);
      if (!mounted) return;
      setState(() {
        _capped = snap.docs.length >= _fetchLimit;
        _buckets = AsyncSnapshot.withData(ConnectionState.done, buckets);
      });
    } catch (e, st) {
      if (mounted) setState(() => _buckets = AsyncSnapshot.withError(ConnectionState.done, e, st));
    }
  }

  @override
  Widget build(BuildContext context) => WeeklyBars(
        title: _capped ? '${widget.title} (first $_fetchLimit)' : widget.title,
        color: widget.color,
        buckets: _buckets,
      );
}

// ---------------------------------------------------------------------------
// Needs attention
// ---------------------------------------------------------------------------

class _AttentionLoader extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String section;
  final ValueChanged<String> onOpen;
  final Future<List<AttentionRow>> Function() load;

  const _AttentionLoader({
    required this.title,
    required this.icon,
    required this.color,
    required this.section,
    required this.onOpen,
    required this.load,
  });

  @override
  State<_AttentionLoader> createState() => _AttentionLoaderState();
}

class _AttentionLoaderState extends State<_AttentionLoader> {
  AsyncSnapshot<List<AttentionRow>> _rows = const AsyncSnapshot.waiting();

  @override
  void initState() {
    super.initState();
    widget.load().then(
      (rows) {
        if (mounted) setState(() => _rows = AsyncSnapshot.withData(ConnectionState.done, rows));
      },
      onError: (Object e, StackTrace st) {
        if (mounted) setState(() => _rows = AsyncSnapshot.withError(ConnectionState.done, e, st));
      },
    );
  }

  @override
  Widget build(BuildContext context) => AttentionGroup(
        title: widget.title,
        icon: widget.icon,
        color: widget.color,
        rows: _rows,
        actionLabel: 'Open ${widget.section}',
        onAction: () => widget.onOpen(widget.section),
      );
}
