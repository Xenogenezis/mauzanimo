import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/screens/pets/edit_pet_screen.dart';

class MyPetsScreen extends StatelessWidget {
  const MyPetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: Text('My listed pets')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
          .collection('pets')
          .where('uploadedBy', isEqualTo: user?.uid)
          .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator(color: AppTheme.primary));
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty)
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.pets, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('You have not listed any pets yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
            ]));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final petId = docs[index].id;
              final status = data['status'] ?? 'available';
              final statusColor = status == 'adopted' ? Colors.green : status == 'pending' ? Colors.orange : AppTheme.primary;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(data['name'] ?? 'Unknown',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text(status[0].toUpperCase() + status.substring(1),
                          style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.category_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(data['type'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(width: 12),
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(data['location'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    ]),
                    const SizedBox(height: 12),
                    if (status != 'adopted') ...[                    
                      ElevatedButton.icon(
                        onPressed: () => _confirmAdopted(context, petId, data['name']),
                        icon: const Icon(Icons.favorite, size: 16),
                        label: Text('Mark as adopted'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(double.infinity, 42),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => EditPetScreen(petId: petId, pet: data))),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            side: const BorderSide(color: AppTheme.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmDelete(context, petId, data['name']),
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: Text('Delete'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ]),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmAdopted(BuildContext context, String petId, String? name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.favorite, color: Colors.green),
          SizedBox(width: 8),
          Text('Mark as adopted'),
        ]),
        content: Text('${name ?? 'This pet'} has found a home! Mark this listing as adopted?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance.collection('pets').doc(petId).update({'status': 'adopted'});
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${name ?? 'Pet'} has been marked as adopted!')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Yes adopted'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String petId, String? name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete listing'),
        content: Text('Are you sure you want to delete the listing for ${name ?? 'this pet'}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance.collection('pets').doc(petId).delete();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Listing deleted successfully')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}
