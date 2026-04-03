import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/screens/pets/pet_list_screen.dart';
import 'package:stray_pets_mu/screens/auth/login_screen.dart';
import 'package:stray_pets_mu/screens/profile_screen.dart';
import 'package:stray_pets_mu/screens/favourites_screen.dart';
import 'package:stray_pets_mu/screens/pets/upload_pet_screen.dart';
import 'package:stray_pets_mu/screens/drawer_menu.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [PetListScreen(), const FavouritesScreen(), const ProfileScreen()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
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
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UploadPetScreen())),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('List a Pet', style: TextStyle(color: Colors.white)),
      ) : null,
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
