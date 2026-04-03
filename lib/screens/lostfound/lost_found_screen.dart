import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/screens/lostfound/add_lost_found_screen.dart';

class LostFoundScreen extends StatefulWidget {
  const LostFoundScreen({super.key});
  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}
class _LostFoundScreenState extends State<LostFoundScreen> {
  String _filter = 'All';
  final _filters = ['All', 'Lost', 'Found'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lost & Found')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddLostFoundScreen())),
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Post report', style: TextStyle(color: Colors.white)),
      ),
      body: Column(children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.orange.withOpacity(0.1),
          child: const Row(children: [
            Icon(Icons.info_outline, color: Colors.orange, size: 18),
            SizedBox(width: 8),
            Expanded(child: Text('Report a lost or found animal in your ar',
              style: TextStyle(fontSize: 13, color: AppTheme.textDark))),
          ]),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filters.length,
            itemBuilder: (context, index) {
              final f = _filters[index];
              final isSelected = f == _filter;
              return GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.orange : AppTheme.lightGrey,
                    borderRadius: BorderRadius.circular(20)),
                  child: Text(f, style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textDark,
                    fontWeight: FontWeight.w500)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _filter == 'All'
              ? FirebaseFirestore.instance.collection('lostfound').orderBy('createdAt', descending: true).snapshots()
              : FirebaseFirestore.instance.collection('lostfound').where('type', isEqualTo: _filter).orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return Center(child: CircularProgressIndicator(color: Colors.orange));
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty)
                return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No reports yet', style: TextStyle(color: Colors.grey)),
                ]));
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final isLost = data['type'] == 'Lost';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))]),
                    child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isLost ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20)),
                          child: Text(data['type'] ?? 'Lost',
                            style: TextStyle(fontSize: 11, color: isLost ? Colors.red : Colors.green, fontWeight: FontWeight.w600)),
                        ),
                        Text(data['animalType'] ?? 'Animal', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ]),
                      const SizedBox(height: 8),
                      Text(data['description'] ?? '', style: TextStyle(fontSize: 14, color: AppTheme.textDark.withOpacity(0.7), height: 1.5)),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(data['location'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.phone_outlined, size: 14, color: AppTheme.primary),
                        const SizedBox(width: 4),
                        Text(data['contact'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.primary)),
                      ]),
                    ])),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
