const fs = require('fs');
const path = require('path');
function write(p, c) {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, c);
  console.log('Written: ' + p);
}

write('lib/screens/lostfound/lost_found_screen.dart', `import 'package:flutter/material.dart';
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
      appBar: AppBar(title: const Text('Lost & Found')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddLostFoundScreen())),
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Post Report', style: TextStyle(color: Colors.white)),
      ),
      body: Column(children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.orange.withOpacity(0.1),
          child: const Row(children: [
            Icon(Icons.info_outline, color: Colors.orange, size: 18),
            SizedBox(width: 8),
            Expanded(child: Text('Report a lost or found animal in your area.',
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
                return const Center(child: CircularProgressIndicator(color: Colors.orange));
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty)
                return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No reports yet', style: TextStyle(color: Colors.grey)),
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
`);

write('lib/screens/lostfound/add_lost_found_screen.dart', `import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';

class AddLostFoundScreen extends StatefulWidget {
  const AddLostFoundScreen({super.key});
  @override
  State<AddLostFoundScreen> createState() => _AddLostFoundScreenState();
}
class _AddLostFoundScreenState extends State<AddLostFoundScreen> {
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();
  final _imageUrlController = TextEditingController();
  String _type = 'Lost';
  String _animalType = 'Dog';
  bool _isLoading = false;
  bool _submitted = false;
  final _types = ['Lost', 'Found'];
  final _animalTypes = ['Dog', 'Cat', 'Other'];

  Future<void> _submit() async {
    if (_descriptionController.text.isEmpty || _locationController.text.isEmpty || _contactController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all required fields')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('lostfound').add({
        'type': _type, 'animalType': _animalType,
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'contact': _contactController.text.trim(),
        'imageUrl': _imageUrlController.text.trim(),
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      setState(() => _submitted = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Something went wrong.')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Lost & Found')),
      body: _submitted ? _success() : _form(),
    );
  }

  Widget _success() => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.check_circle_outline, size: 100, color: Colors.orange),
      const SizedBox(height: 24),
      const Text('Report Posted!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
      const SizedBox(height: 12),
      const Text('Your report has been posted successfully!', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)),
      const SizedBox(height: 32),
      ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
    ])));

  Widget _form() => SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Report Type', style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textDark)),
      const SizedBox(height: 8),
      Row(children: _types.map((t) => GestureDetector(
        onTap: () => setState(() => _type = t),
        child: Container(margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: _type == t ? (_type == 'Lost' ? Colors.red : Colors.green) : AppTheme.lightGrey,
            borderRadius: BorderRadius.circular(20)),
          child: Text(t, style: TextStyle(color: _type == t ? Colors.white : AppTheme.textDark, fontWeight: FontWeight.w500))))).toList()),
      const SizedBox(height: 16),
      const Text('Animal Type', style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textDark)),
      const SizedBox(height: 8),
      Row(children: _animalTypes.map((t) => GestureDetector(
        onTap: () => setState(() => _animalType = t),
        child: Container(margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _animalType == t ? AppTheme.primary : AppTheme.lightGrey,
            borderRadius: BorderRadius.circular(20)),
          child: Text(t, style: TextStyle(color: _animalType == t ? Colors.white : AppTheme.textDark, fontWeight: FontWeight.w500))))).toList()),
      const SizedBox(height: 16),
      _f(_descriptionController, 'Describe the animal', Icons.description_outlined, maxLines: 3),
      const SizedBox(height: 16),
      _f(_locationController, 'Last seen location', Icons.location_on_outlined),
      const SizedBox(height: 16),
      _f(_contactController, 'Your contact number', Icons.phone_outlined, keyboardType: TextInputType.phone),
      const SizedBox(height: 16),
      _f(_imageUrlController, 'Photo URL (optional)', Icons.image_outlined),
      const SizedBox(height: 32),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Post Report', style: TextStyle(fontSize: 16)))),
    ]));

  Widget _f(TextEditingController c, String label, IconData icon,
    {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) =>
    TextField(controller: c, keyboardType: keyboardType, maxLines: maxLines,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2))));
}
`);
