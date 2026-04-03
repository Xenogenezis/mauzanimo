const fs = require('fs');
const path = require('path');

fs.mkdirSync('lib/screens/pets', { recursive: true });

fs.writeFileSync('lib/screens/pets/my_pets_screen.dart', `import 'package:flutter/material.dart';
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
      appBar: AppBar(title: const Text('My Listed Pets')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
          .collection('pets')
          .where('uploadedBy', isEqualTo: user?.uid)
          .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty)
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.pets, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text('You have not listed any pets yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
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
                    Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => EditPetScreen(petId: petId, pet: data))),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Edit'),
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
                          label: const Text('Delete'),
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

  void _confirmDelete(BuildContext context, String petId, String? name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Listing'),
        content: Text('Are you sure you want to delete the listing for \${name ?? 'this pet'}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance.collection('pets').doc(petId).delete();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Listing deleted successfully.')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
`);
console.log('MyPetsScreen written!');

fs.writeFileSync('lib/screens/pets/edit_pet_screen.dart', `import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';

class EditPetScreen extends StatefulWidget {
  final String petId;
  final Map<String, dynamic> pet;
  const EditPetScreen({super.key, required this.petId, required this.pet});
  @override
  State<EditPetScreen> createState() => _EditPetScreenState();
}
class _EditPetScreenState extends State<EditPetScreen> {
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late TextEditingController _ageController;
  late TextEditingController _contactController;
  late String _type;
  late String _gender;
  late bool _vaccinated;
  late bool _sterilized;
  late bool _dewormed;
  bool _isLoading = false;
  final _types = ['dogs', 'cats', 'others'];
  final _genders = ['Male', 'Female'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pet['name'] ?? '');
    _locationController = TextEditingController(text: widget.pet['location'] ?? '');
    _descriptionController = TextEditingController(text: widget.pet['description'] ?? '');
    _ageController = TextEditingController(text: widget.pet['age'] ?? '');
    _contactController = TextEditingController(text: widget.pet['contact'] ?? '');
    _type = widget.pet['type'] ?? 'dogs';
    _gender = widget.pet['gender'] ?? 'Male';
    _vaccinated = widget.pet['vaccinated'] == true;
    _sterilized = widget.pet['sterilized'] == true;
    _dewormed = widget.pet['dewormed'] == true;
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all required fields')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('pets').doc(widget.petId).update({
        'name': _nameController.text.trim(),
        'type': _type,
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'age': _ageController.text.trim(),
        'gender': _gender,
        'contact': _contactController.text.trim(),
        'vaccinated': _vaccinated,
        'sterilized': _sterilized,
        'dewormed': _dewormed,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing updated successfully!')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Something went wrong. Please try again.')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Listing')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [
              Icon(Icons.edit_outlined, color: AppTheme.primary),
              SizedBox(width: 12),
              Expanded(child: Text('Update your pet listing details below.', style: TextStyle(fontSize: 13, color: AppTheme.textDark))),
            ]),
          ),
          const SizedBox(height: 20),
          _f(_nameController, 'Pet Name', Icons.pets),
          const SizedBox(height: 16),
          _f(_ageController, 'Age', Icons.cake_outlined),
          const SizedBox(height: 16),
          _f(_locationController, 'Location', Icons.location_on_outlined),
          const SizedBox(height: 16),
          _f(_descriptionController, 'Description', Icons.description_outlined, maxLines: 4),
          const SizedBox(height: 16),
          _f(_contactController, 'Contact Number', Icons.phone_outlined, keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          const Text('Type', style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textDark)),
          const SizedBox(height: 8),
          Row(children: _types.map((t) => GestureDetector(
            onTap: () => setState(() => _type = t),
            child: Container(margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _type == t ? AppTheme.primary : AppTheme.lightGrey,
                borderRadius: BorderRadius.circular(20)),
              child: Text(t[0].toUpperCase() + t.substring(1),
                style: TextStyle(color: _type == t ? Colors.white : AppTheme.textDark, fontWeight: FontWeight.w500))))).toList()),
          const SizedBox(height: 16),
          const Text('Gender', style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textDark)),
          const SizedBox(height: 8),
          Row(children: _genders.map((g) => GestureDetector(
            onTap: () => setState(() => _gender = g),
            child: Container(margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _gender == g ? AppTheme.primary : AppTheme.lightGrey,
                borderRadius: BorderRadius.circular(20)),
              child: Text(g, style: TextStyle(color: _gender == g ? Colors.white : AppTheme.textDark, fontWeight: FontWeight.w500))))).toList()),
          SwitchListTile(title: const Text('Vaccinated'), value: _vaccinated, activeColor: AppTheme.primary, onChanged: (v) => setState(() => _vaccinated = v)),
          SwitchListTile(title: const Text('Sterilized'), value: _sterilized, activeColor: AppTheme.primary, onChanged: (v) => setState(() => _sterilized = v)),
          SwitchListTile(title: const Text('Dewormed'), value: _dewormed, activeColor: AppTheme.primary, onChanged: (v) => setState(() => _dewormed = v)),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Changes', style: TextStyle(fontSize: 16)))),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _f(TextEditingController c, String label, IconData icon,
    {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) =>
    TextField(controller: c, keyboardType: keyboardType, maxLines: maxLines,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2))));
}
`);
console.log('EditPetScreen written!');
