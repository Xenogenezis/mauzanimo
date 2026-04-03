import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/screens/stories/add_story_screen.dart';

class SuccessStoriesScreen extends StatelessWidget {
  const SuccessStoriesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Success Stories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddStoryScreen())),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Share your story', style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('stories').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator(color: AppTheme.primary));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.auto_stories_outlined, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('No stories yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 8),
              Text('Be the first to share your adoption stor', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ]));
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                      child: Image.network(data['imageUrl'], height: 200, width: double.infinity, fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(height: 200, color: AppTheme.lightGrey,
                          child: Center(child: Icon(Icons.pets, size: 48, color: AppTheme.primary)))),
                    ),
                  Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: const Row(children: [
                          Icon(Icons.favorite, size: 12, color: Colors.green),
                          SizedBox(width: 4),
                          Text('Adopted', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600)),
                        ])),
                      const SizedBox(width: 8),
                      Text(data['petName'] ?? 'Unknown Pet',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark)),
                    ]),
                    const SizedBox(height: 8),
                    Text(data['story'] ?? '',
                      style: TextStyle(fontSize: 14, color: AppTheme.textDark.withOpacity(0.7), height: 1.6)),
                    const SizedBox(height: 12),
                    Row(children: [
                      const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(data['adopterName'] ?? 'Anonymous', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ]),
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