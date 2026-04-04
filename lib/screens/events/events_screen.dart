import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../lang/app_strings.dart';
import '../providers/language_provider.dart';
import '../providers/event_provider.dart';
import '../providers/auth_provider.dart';
import '../models/event_registration.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).lang;
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('events', lang)),
        actions: [
          // Show user's registrations button
          if (user != null)
            IconButton(
              icon: const Icon(Icons.confirmation_number_outlined),
              onPressed: () => _showMyRegistrations(context),
              tooltip: AppStrings.get('my_event_registrations', lang),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .orderBy('date', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.get('no_upcoming_events', lang),
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.get('check_back_soon_for_adoption_events_near', lang),
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final eventId = docs[index].id;

              return EventCard(
                eventId: eventId,
                data: data,
                user: user,
              );
            },
          );
        },
      ),
    );
  }

  void _showMyRegistrations(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const MyEventRegistrationsSheet(),
    );
  }
}

/// Event card with registration button
class EventCard extends StatelessWidget {
  final String eventId;
  final Map<String, dynamic> data;
  final User? user;

  const EventCard({
    super.key,
    required this.eventId,
    required this.data,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).lang;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Image.network(
                data['imageUrl'],
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  height: 160,
                  color: AppTheme.lightGrey,
                  child: Center(
                    child: Icon(Icons.event, size: 48, color: AppTheme.primary),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        AppStrings.get('upcoming', lang),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  data['title'] ?? 'Event',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data['description'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textDark.withOpacity(0.7),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 14, color: AppTheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      data['date'] ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time_outlined,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      data['time'] ?? '',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      data['location'] ?? '',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (user != null)
                  EventRegistrationButton(
                    eventId: eventId,
                    eventData: data,
                    user: user!,
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              lang == 'fr'
                                  ? 'Veuillez vous connecter pour vous inscrire'
                                  : 'Please sign in to register',
                            ),
                          ),
                        );
                      },
                      child: Text(AppStrings.get('register_interest', lang)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Registration button with stream to check registration status
class EventRegistrationButton extends StatelessWidget {
  final String eventId;
  final Map<String, dynamic> eventData;
  final User user;

  const EventRegistrationButton({
    super.key,
    required this.eventId,
    required this.eventData,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).lang;
    final eventProvider = Provider.of<EventProvider>(context);

    return StreamBuilder<bool>(
      stream: eventProvider.isUserRegisteredForEvent(
        eventId: eventId,
        userId: user.uid,
      ),
      builder: (context, snapshot) {
        final isRegistered = snapshot.data ?? false;

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: eventProvider.isLoading
                ? null
                : () => _handleRegistration(context, isRegistered),
            style: ElevatedButton.styleFrom(
              backgroundColor: isRegistered ? Colors.grey : AppTheme.primary,
            ),
            child: eventProvider.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    isRegistered
                        ? AppStrings.get('cancel_registration', lang)
                        : AppStrings.get('register_interest', lang),
                  ),
          ),
        );
      },
    );
  }

  Future<void> _handleRegistration(BuildContext context, bool isRegistered) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false).lang;
    final eventProvider = Provider.of<EventProvider>(context, listen: false);

    if (isRegistered) {
      // Cancel registration
      final success = await eventProvider.cancelRegistration(
        eventId: eventId,
        userId: user.uid,
      );

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.get('event_registration_cancelled', lang)),
          ),
        );
      }
    } else {
      // Show registration dialog to collect user info
      final result = await showDialog<Map<String, String>>(
        context: context,
        builder: (context) => EventRegistrationDialog(
          eventTitle: eventData['title'] ?? 'Event',
          user: user,
        ),
      );

      if (result != null && context.mounted) {
        final success = await eventProvider.registerForEvent(
          eventId: eventId,
          userId: user.uid,
          userName: result['name']!,
          userEmail: result['email']!,
          userPhone: result['phone'],
        );

        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.get('event_registration_success', lang),
              ),
            ),
          );
        }
      }
    }
  }
}

/// Dialog to collect registration information
class EventRegistrationDialog extends StatefulWidget {
  final String eventTitle;
  final User user;

  const EventRegistrationDialog({
    super.key,
    required this.eventTitle,
    required this.user,
  });

  @override
  State<EventRegistrationDialog> createState() =>
      _EventRegistrationDialogState();
}

class _EventRegistrationDialogState extends State<EventRegistrationDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill with user's info if available
    _nameController = TextEditingController(text: widget.user.displayName ?? '');
    _emailController = TextEditingController(text: widget.user.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).lang;

    return AlertDialog(
      title: Text(AppStrings.get('register_interest', lang)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.eventTitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: AppStrings.get('full_name', lang),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: AppStrings.get('email', lang),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: AppStrings.get('phone', lang),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(lang == 'fr' ? 'Annuler' : 'Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isEmpty ||
                _emailController.text.isEmpty) {
              return;
            }
            Navigator.of(context).pop({
              'name': _nameController.text,
              'email': _emailController.text,
              'phone': _phoneController.text.isEmpty
                  ? null
                  : _phoneController.text,
            });
          },
          child: Text(AppStrings.get('submit_inquiry', lang)),
        ),
      ],
    );
  }
}

/// Bottom sheet showing user's event registrations
class MyEventRegistrationsSheet extends StatelessWidget {
  const MyEventRegistrationsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).lang;
    final user = Provider.of<AuthProvider>(context).user;
    final eventProvider = Provider.of<EventProvider>(context);

    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Text(lang == 'fr'
            ? 'Veuillez vous connecter'
            : 'Please sign in'),
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 16),
          Text(
            AppStrings.get('my_event_registrations', lang),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<EventRegistration>>(
              stream: eventProvider.getUserRegistrations(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final registrations = snapshot.data ?? [];

                if (registrations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.get('no_event_registrations', lang),
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: registrations.length,
                  itemBuilder: (context, index) {
                    final registration = registrations[index];
                    return _RegistrationCard(
                      registration: registration,
                      userId: user.uid,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Card showing a single registration with event details
class _RegistrationCard extends StatelessWidget {
  final EventRegistration registration;
  final String userId;

  const _RegistrationCard({
    required this.registration,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).lang;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('events')
          .doc(registration.eventId)
          .get(),
      builder: (context, snapshot) {
        final eventData =
            snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final eventTitle = eventData['title'] ?? 'Event';
        final eventDate = eventData['date'] ?? '';
        final eventLocation = eventData['location'] ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primary.withOpacity(0.1),
              child: Icon(Icons.event, color: AppTheme.primary),
            ),
            title: Text(eventTitle),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$eventDate • $eventLocation'),
                Text(
                  registration.status == 'registered'
                      ? AppStrings.get('registered', lang)
                      : registration.status,
                  style: TextStyle(
                    color: registration.status == 'registered'
                        ? Colors.green
                        : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            trailing: registration.status == 'registered'
                ? TextButton(
                    onPressed: () async {
                      final eventProvider =
                          Provider.of<EventProvider>(context, listen: false);
                      final success = await eventProvider.cancelRegistration(
                        eventId: registration.eventId,
                        userId: userId,
                      );

                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppStrings.get(
                                  'event_registration_cancelled', lang),
                            ),
                          ),
                        );
                      }
                    },
                    child: Text(
                      AppStrings.get('cancel', lang),
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}
