const fs = require('fs');
const path = require('path');

function write(filePath, content) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, content);
  console.log('Written: ' + filePath + ' (' + fs.statSync(filePath).size + ' bytes)');
}

write('lib/screens/home_screen.dart', `import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/screens/pets/pet_list_screen.dart';
import 'package:stray_pets_mu/screens/auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [PetListScreen()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.pets, color: Colors.white),
          SizedBox(width: 8),
          Text('MauZanimo', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => LoginScreen()));
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Pets'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_outline), label: 'Saved'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
`);
write('lib/screens/auth/login_screen.dart', `import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  Future<void> _login() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => HomeScreen()));
    } on FirebaseAuthException catch (e) {
      setState(() { _errorMessage = e.message; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Center(child: Icon(Icons.pets, size: 80, color: AppTheme.primary)),
              const SizedBox(height: 16),
              const Center(child: Text('MauZanimo',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textDark))),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Sign In'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
`);
write('lib/screens/pets/pet_card.dart', `import 'package:flutter/material.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';

class PetCard extends StatelessWidget {
  final Map<String, dynamic> pet;
  final String petId;
  final VoidCallback onTap;
  const PetCard({super.key, required this.pet, required this.petId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                child: pet['imageUrl'] != null
                  ? Image.network(pet['imageUrl'], fit: BoxFit.cover, width: double.infinity,
                      errorBuilder: (c, e, s) => _placeholder())
                  : _placeholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pet['name'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                    const SizedBox(width: 2),
                    Expanded(child: Text(pet['location'] ?? 'Mauritius',
                      style: const TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(pet['type'] ?? 'Pet',
                      style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _placeholder() {
    return Container(color: AppTheme.lightGrey,
      child: const Center(child: Icon(Icons.pets, size: 48, color: AppTheme.primary)));
  }
}
`);
write('lib/screens/pets/pet_list_screen.dart', `import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/screens/pets/pet_card.dart';
import 'package:stray_pets_mu/screens/pets/pet_detail_screen.dart';

class PetListScreen extends StatefulWidget {
  const PetListScreen({super.key});
  @override
  State<PetListScreen> createState() => _PetListScreenState();
}
class _PetListScreenState extends State<PetListScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Dogs', 'Cats', 'Others'];
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Find a companion', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Give a stray pet a loving home', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: const TextField(
                  decoration: InputDecoration(hintText: 'Search pets...', border: InputBorder.none,
                    icon: Icon(Icons.search, color: AppTheme.primary)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filters.length,
            itemBuilder: (context, index) {
              final filter = _filters[index];
              final isSelected = filter == _selectedFilter;
              return GestureDetector(
                onTap: () => setState(() => _selectedFilter = filter),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : AppTheme.lightGrey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(filter, style: TextStyle(color: isSelected ? Colors.white : AppTheme.textDark, fontWeight: FontWeight.w500)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _selectedFilter == 'All'
              ? FirebaseFirestore.instance.collection('pets').snapshots()
              : FirebaseFirestore.instance.collection('pets').where('type', isEqualTo: _selectedFilter.toLowerCase()).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.pets, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No pets available yet', style: TextStyle(color: Colors.grey)),
                ]));
              final pets = snapshot.data!.docs;
              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.75),
                itemCount: pets.length,
                itemBuilder: (context, index) {
                  final pet = pets[index].data() as Map<String, dynamic>;
                  final petId = pets[index].id;
                  return PetCard(pet: pet, petId: petId,
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => PetDetailScreen(pet: pet, petId: petId))));
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
`);
write('lib/screens/pets/pet_detail_screen.dart', `import 'package:flutter/material.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/screens/adoption/adoption_inquiry_screen.dart';

class PetDetailScreen extends StatelessWidget {
  final Map<String, dynamic> pet;
  final String petId;
  const PetDetailScreen({super.key, required this.pet, required this.petId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300, pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: pet['imageUrl'] != null
                ? Image.network(pet['imageUrl'], fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => _placeholder())
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
                  ]),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: pet['status'] == 'adopted' ? null : () =>
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => AdoptionInquiryScreen(pet: pet, petId: petId))),
                      child: const Text('Start Adoption Process', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
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
`);
write('lib/screens/adoption/adoption_inquiry_screen.dart', `import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';

class AdoptionInquiryScreen extends StatefulWidget {
  final Map<String, dynamic> pet;
  final String petId;
  const AdoptionInquiryScreen({super.key, required this.pet, required this.petId});
  @override
  State<AdoptionInquiryScreen> createState() => _AdoptionInquiryScreenState();
}
class _AdoptionInquiryScreenState extends State<AdoptionInquiryScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;
  bool _submitted = false;

  Future<void> _submit() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all required fields')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('inquiries').add({
        'petId': widget.petId,
        'petName': widget.pet['name'],
        'applicantName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'message': _messageController.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth.instance.currentUser?.uid,
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
      appBar: AppBar(title: const Text('Adoption Inquiry')),
      body: _submitted ? _success() : _form(),
    );
  }

  Widget _success() => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.check_circle_outline, size: 100, color: AppTheme.primary),
      const SizedBox(height: 24),
      const Text('Inquiry Submitted!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
      const SizedBox(height: 12),
      const Text('Thank you! Our team will get in touch with you shortly.',
        textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)),
      const SizedBox(height: 32),
      ElevatedButton(
        onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
        child: const Text('Back to Home')),
    ])));

  Widget _form() => SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Your Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
      const SizedBox(height: 16),
      _field(_nameController, 'Full Name', Icons.person_outline),
      const SizedBox(height: 16),
      _field(_emailController, 'Email', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
      const SizedBox(height: 16),
      _field(_phoneController, 'Phone', Icons.phone_outlined, keyboardType: TextInputType.phone),
      const SizedBox(height: 16),
      _field(_messageController, 'Why do you want to adopt?', Icons.message_outlined, maxLines: 4),
      const SizedBox(height: 32),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit Inquiry'))),
    ]));

  Widget _field(TextEditingController c, String label, IconData icon,
    {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) =>
    TextField(controller: c, keyboardType: keyboardType, maxLines: maxLines,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2))));
}
`);
write('lib/screens/admin/admin_dashboard.dart', `import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/screens/admin/add_pet_screen.dart';
import 'package:stray_pets_mu/screens/admin/inquiries_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _StatCard(label: 'Total Pets', icon: Icons.pets, color: AppTheme.primary,
              stream: FirebaseFirestore.instance.collection('pets').snapshots())),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: 'Inquiries', icon: Icons.mail_outline, color: AppTheme.accent,
              stream: FirebaseFirestore.instance.collection('inquiries').snapshots())),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _StatCard(label: 'Adopted', icon: Icons.favorite, color: Colors.green,
              stream: FirebaseFirestore.instance.collection('pets').where('status', isEqualTo: 'adopted').snapshots())),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: 'Pending', icon: Icons.hourglass_empty, color: Colors.orange,
              stream: FirebaseFirestore.instance.collection('inquiries').where('status', isEqualTo: 'pending').snapshots())),
          ]),
          const SizedBox(height: 32),
          const Text('Quick Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 16),
          _Tile(icon: Icons.add_circle_outline, title: 'Add New Pet', subtitle: 'Register a new pet',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddPetScreen()))),
          const SizedBox(height: 12),
          _Tile(icon: Icons.inbox_outlined, title: 'View Inquiries', subtitle: 'Manage adoption inquiries',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InquiriesScreen()))),
        ],
      )),
    );
  }
}
class _StatCard extends StatelessWidget {
  final String label; final IconData icon; final Color color; final Stream<QuerySnapshot> stream;
  const _StatCard({required this.label, required this.icon, required this.color, required this.stream});
  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot>(
    stream: stream,
    builder: (c, s) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 28), const SizedBox(height: 12),
        Text('${s.data?.docs.length ?? 0}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textDark)),
      ]),
    ));
}
class _Tile extends StatelessWidget {
  final IconData icon; final String title, subtitle; final VoidCallback onTap;
  const _Tile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))]),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: AppTheme.primary)),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ])),
      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
    ]),
  ));
}
`);

write('lib/screens/admin/add_pet_screen.dart', `import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});
  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}
class _AddPetScreenState extends State<AddPetScreen> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _ageController = TextEditingController();
  String _type = 'dogs'; String _gender = 'Male';
  bool _vaccinated = false; bool _sterilized = false; bool _isLoading = false;
  final _types = ['dogs', 'cats', 'others'];
  final _genders = ['Male', 'Female'];

  Future<void> _save() async {
    if (_nameController.text.isEmpty || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill required fields')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('pets').add({
        'name': _nameController.text.trim(), 'type': _type,
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': _imageUrlController.text.trim(),
        'age': _ageController.text.trim(), 'gender': _gender,
        'vaccinated': _vaccinated, 'sterilized': _sterilized,
        'status': 'available', 'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pet added!')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Something went wrong.')));
    } finally { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Add New Pet')),
    body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _f(_nameController, 'Pet Name', Icons.pets),
        const SizedBox(height: 16), _f(_ageController, 'Age', Icons.cake_outlined),
        const SizedBox(height: 16), _f(_locationController, 'Location', Icons.location_on_outlined),
        const SizedBox(height: 16), _f(_imageUrlController, 'Image URL', Icons.image_outlined),
        const SizedBox(height: 16), _f(_descriptionController, 'Description', Icons.description_outlined, maxLines: 4),
        const SizedBox(height: 16),
        const Text('Type', style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textDark)),
        const SizedBox(height: 8),
        Row(children: _types.map((t) => GestureDetector(
          onTap: () => setState(() => _type = t),
          child: Container(margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: _type == t ? AppTheme.primary : AppTheme.lightGrey, borderRadius: BorderRadius.circular(20)),
            child: Text(t[0].toUpperCase() + t.substring(1),
              style: TextStyle(color: _type == t ? Colors.white : AppTheme.textDark, fontWeight: FontWeight.w500)))
        )).toList()),
        const SizedBox(height: 16),
        const Text('Gender', style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textDark)),
        const SizedBox(height: 8),
        Row(children: _genders.map((g) => GestureDetector(
          onTap: () => setState(() => _gender = g),
          child: Container(margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: _gender == g ? AppTheme.primary : AppTheme.lightGrey, borderRadius: BorderRadius.circular(20)),
            child: Text(g, style: TextStyle(color: _gender == g ? Colors.white : AppTheme.textDark, fontWeight: FontWeight.w500)))
        )).toList()),
        SwitchListTile(title: const Text('Vaccinated'), value: _vaccinated, activeColor: AppTheme.primary, onChanged: (v) => setState(() => _vaccinated = v)),
        SwitchListTile(title: const Text('Sterilized'), value: _sterilized, activeColor: AppTheme.primary, onChanged: (v) => setState(() => _sterilized = v)),
        const SizedBox(height: 32),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Pet'))),
      ],
    )),
  );
  Widget _f(TextEditingController c, String label, IconData icon, {int maxLines = 1}) =>
    TextField(controller: c, maxLines: maxLines, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primary, width: 2))));
}
`);

write('lib/screens/admin/inquiries_screen.dart', `import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';

class InquiriesScreen extends StatelessWidget {
  const InquiriesScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Adoption Inquiries')),
    body: StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('inquiries').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('No inquiries yet', style: TextStyle(color: Colors.grey)),
          ]));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final id = snapshot.data!.docs[index].id;
            return Container(
              margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(data['applicantName'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark)),
                  _Badge(status: data['status'] ?? 'pending'),
                ]),
                const SizedBox(height: 6),
                Text('Pet: ${data['petName'] ?? 'Unknown'}', style: const TextStyle(fontSize: 13, color: AppTheme.primary)),
                Text(data['email'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                Text(data['phone'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => _update(id, 'rejected'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: const Text('Reject'))),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(
                    onPressed: () => _update(id, 'approved'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: const Text('Approve'))),
                ]),
              ]),
            );
          });
      }),
  );
  Future<void> _update(String id, String status) =>
    FirebaseFirestore.instance.collection('inquiries').doc(id).update({'status': status});
}
class _Badge extends StatelessWidget {
  final String status;
  const _Badge({required this.status});
  @override
  Widget build(BuildContext context) {
    final color = status == 'approved' ? Colors.green : status == 'rejected' ? Colors.red : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status[0].toUpperCase() + status.substring(1),
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)));
  }
}
`);
