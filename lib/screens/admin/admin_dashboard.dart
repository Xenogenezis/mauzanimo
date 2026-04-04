import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/screens/admin/add_pet_screen.dart';
import 'package:stray_pets_mu/screens/admin/inquiries_screen.dart';
import 'package:stray_pets_mu/models/user_role.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const _OverviewTab(),
    const _UserManagementTab(),
    const _RoleRequestsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.pending_outlined),
            selectedIcon: Icon(Icons.pending),
            label: 'Requests',
          ),
        ],
      ),
    );
  }
}

// Overview Tab
class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Total Pets',
                  icon: Icons.pets,
                  color: AppTheme.primary,
                  stream: FirebaseFirestore.instance.collection('pets').snapshots(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Inquiries',
                  icon: Icons.mail_outline,
                  color: AppTheme.accent,
                  stream: FirebaseFirestore.instance.collection('inquiries').snapshots(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Adopted',
                  icon: Icons.favorite,
                  color: Colors.green,
                  stream: FirebaseFirestore.instance
                      .collection('pets')
                      .where('status', isEqualTo: 'adopted')
                      .snapshots(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Pending',
                  icon: Icons.hourglass_empty,
                  color: Colors.orange,
                  stream: FirebaseFirestore.instance
                      .collection('inquiries')
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          _ActionTile(
            icon: Icons.add_circle_outline,
            title: 'Add New Pet',
            subtitle: 'Register a new pet',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddPetScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.inbox_outlined,
            title: 'View Inquiries',
            subtitle: 'Manage adoption inquiries',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InquiriesScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.person_add_outlined,
            title: 'Create Admin/Partner',
            subtitle: 'Create special user accounts',
            onTap: () => _showCreateSpecialUserDialog(context),
          ),
        ],
      ),
    );
  }

  void _showCreateSpecialUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _CreateSpecialUserDialog(),
    );
  }
}

// User Management Tab
class _UserManagementTab extends StatelessWidget {
  const _UserManagementTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final data = user.data() as Map<String, dynamic>;
            final role = UserRoleExtension.fromString(data['role'] as String?);

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getRoleColor(role).withValues(alpha: 0.2),
                  child: Icon(
                    _getRoleIcon(role),
                    color: _getRoleColor(role),
                    size: 20,
                  ),
                ),
                title: Text(data['name'] ?? 'Unknown'),
                subtitle: Text(data['email'] ?? ''),
                trailing: Chip(
                  label: Text(
                    role.displayName,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: _getRoleColor(role).withValues(alpha: 0.1),
                  side: BorderSide(color: _getRoleColor(role).withValues(alpha: 0.3)),
                ),
                onTap: () => _showUserDetails(context, user.id, data, role),
              ),
            );
          },
        );
      },
    );
  }

  Color _getRoleColor(UserRole role) {
    return switch (role) {
      UserRole.adopter => Colors.blue,
      UserRole.rehomer => Colors.green,
      UserRole.volunteer => Colors.orange,
      UserRole.partner => Colors.purple,
      UserRole.admin => Colors.red,
      UserRole.superAdmin => Colors.deepPurple,
    };
  }

  IconData _getRoleIcon(UserRole role) {
    return switch (role) {
      UserRole.adopter => Icons.favorite,
      UserRole.rehomer => Icons.home,
      UserRole.volunteer => Icons.volunteer_activism,
      UserRole.partner => Icons.business,
      UserRole.admin => Icons.admin_panel_settings,
      UserRole.superAdmin => Icons.supervised_user_circle,
    };
  }

  void _showUserDetails(BuildContext context, String userId,
      Map<String, dynamic> data, UserRole currentRole) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                data['name'] ?? 'User Details',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data['email'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Change Role',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: UserRole.values.map((role) {
                    final isSelected = role == currentRole;
                    return ListTile(
                      leading: Icon(
                        _getRoleIcon(role),
                        color: isSelected ? _getRoleColor(role) : Colors.grey,
                      ),
                      title: Text(role.displayName),
                      subtitle: Text(role.description),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: _getRoleColor(role))
                          : null,
                      onTap: () async {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .update({'role': role.name});
                        if (context.mounted) Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Role Requests Tab
class _RoleRequestsTab extends StatelessWidget {
  const _RoleRequestsTab();

  @override
  Widget build(BuildContext context) {
    // For now, show placeholder. In production, this would show pending role upgrade requests
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_turned_in_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No pending requests',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Role upgrade requests will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

// Create Special User Dialog
class _CreateSpecialUserDialog extends StatefulWidget {
  const _CreateSpecialUserDialog();

  @override
  State<_CreateSpecialUserDialog> createState() =>
      _CreateSpecialUserDialogState();
}

class _CreateSpecialUserDialogState extends State<_CreateSpecialUserDialog> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  UserRole _selectedRole = UserRole.partner;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Only allow admin-created roles
    final adminRoles = [UserRole.partner, UserRole.admin];

    return AlertDialog(
      title: const Text('Create Special User'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Role:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...adminRoles.map((role) => RadioListTile<UserRole>(
                  title: Text(role.displayName),
                  subtitle: Text(role.description),
                  value: role,
                  groupValue: _selectedRole,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedRole = value);
                    }
                  },
                )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createUser,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createUser() async {
    if (_emailController.text.isEmpty || _nameController.text.isEmpty) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create a document in a pending_users collection
      // The actual account would need to be created via Firebase Auth
      await FirebaseFirestore.instance.collection('pending_users').add({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _selectedRole.name,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User creation request submitted. They will receive an email to complete registration.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

// Stat Card Widget
class _StatCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Stream<QuerySnapshot> stream;

  const _StatCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (c, snap) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text(
                (snap.data?.docs.length ?? 0).toString(),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      );
}

// Action Tile Widget
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      );
}
