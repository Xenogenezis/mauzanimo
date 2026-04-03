import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Adoption Events')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('events').orderBy('date', descending: false).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator(color: AppTheme.primary));
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty)
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.event_outlined, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('No upcoming events', style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 8),
              Text('Check back soon for adoption events near', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ]));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                      child: Image.network(data['imageUrl'], height: 160, width: double.infinity, fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(height: 160, color: AppTheme.lightGrey,
                          child: Center(child: Icon(Icons.event, size: 48, color: AppTheme.primary)))),
                    ),
                  Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text('Upcoming', style: TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Text(data['title'] ?? 'Event',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                    const SizedBox(height: 8),
                    Text(data['description'] ?? '',
                      style: TextStyle(fontSize: 14, color: AppTheme.textDark.withOpacity(0.7), height: 1.5)),
                    const SizedBox(height: 12),
                    Row(children: [
                      const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.primary),
                      const SizedBox(width: 6),
                      Text(data['date'] ?? '', style: const TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w500)),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.access_time_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(data['time'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(data['location'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    ]),
                    const SizedBox(height: 16),
                    SizedBox(width: double.infinity, child: ElevatedButton(
                      onPressed: () {},
                      child: Text('Register interest'))),
                  ])),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}
