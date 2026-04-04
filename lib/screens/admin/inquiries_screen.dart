import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../lang/app_strings.dart';
import '../../providers/language_provider.dart';
import '../../repositories/pet_repository.dart';
import '../../utils/result.dart';

class InquiriesScreen extends StatelessWidget {
  const InquiriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).lang;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('adoption_inquiries', lang)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('inquiries')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.get('no_inquiries_yet', lang),
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final data = snapshot.data!.docs[index].data()
                  as Map<String, dynamic>;
              final id = snapshot.data!.docs[index].id;
              final petId = data['petId'] as String?;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            data['applicantName'] ?? 'Unknown',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                        _Badge(status: data['status'] ?? 'pending'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${AppStrings.get('pets', lang)}: ${data['petName'] ?? 'Unknown'}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.primary,
                      ),
                    ),
                    Text(
                      data['email'] ?? '',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    Text(
                      data['phone'] ?? '',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    if (data['message'] != null &&
                        data['message'].toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        data['message'],
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textDark.withOpacity(0.7),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (data['status'] == 'pending')
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _updateStatus(context, id, 'rejected'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(AppStrings.get('reject', lang)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _handleApprove(
                                context,
                                id,
                                petId,
                                data['petName'] ?? 'Unknown',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(AppStrings.get('approve', lang)),
                            ),
                          ),
                        ],
                      )
                    else
                      Center(
                        child: Text(
                          data['status'] == 'approved'
                              ? '${AppStrings.get('approved', lang)}: ${data['updatedAt'] != null ? _formatDate(data['updatedAt']) : ''}'
                              : '${AppStrings.get('rejected', lang)}: ${data['updatedAt'] != null ? _formatDate(data['updatedAt']) : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: data['status'] == 'approved'
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _updateStatus(BuildContext context, String id, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('inquiries')
          .doc(id)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'approved'
                  ? 'Inquiry approved'
                  : 'Inquiry rejected',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  Future<void> _handleApprove(
    BuildContext context,
    String inquiryId,
    String? petId,
    String petName,
  ) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false).lang;

    // First approve the inquiry
    await _updateStatus(context, inquiryId, 'approved');

    // Then ask if admin wants to mark pet as adopted
    if (context.mounted && petId != null) {
      final shouldMarkAdopted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppStrings.get('mark_as_adopted', lang)),
          content: Text(
            lang == 'fr'
                ? 'Voulez-vous marquer $petName comme adopte ? L\'animal n\'apparaitra plus dans les annonces publiques.'
                : 'Would you like to mark $petName as adopted? The pet will no longer appear in public listings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppStrings.get('cancel', lang)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text(AppStrings.get('yes_adopted', lang)),
            ),
          ],
        ),
      );

      if (shouldMarkAdopted == true && context.mounted) {
        await _markPetAsAdopted(context, petId);
      }
    }
  }

  Future<void> _markPetAsAdopted(BuildContext context, String petId) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false).lang;
    final petRepository = PetRepository();

    // Get current pet data first
    final petResult = await petRepository.getPetById(petId);

    await petResult.when(
      success: (pet) async {
        if (pet != null) {
          // Update pet status to adopted
          final updatedPet = pet.copyWith(status: 'adopted');
          final updateResult = await petRepository.updatePet(updatedPet);

          updateResult.when(
            success: (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      lang == 'fr'
                          ? 'Animal marque comme adopte'
                          : 'Pet marked as adopted',
                    ),
                  ),
                );
              }
            },
            failure: (message) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              }
            },
          );
        }
      },
      failure: (message) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      },
    );
  }
}

class _Badge extends StatelessWidget {
  final String status;

  const _Badge({required this.status});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).lang;
    final color = status == 'approved'
        ? Colors.green
        : status == 'rejected'
            ? Colors.red
            : Colors.orange;

    String label;
    switch (status) {
      case 'approved':
        label = AppStrings.get('approved', lang);
        break;
      case 'rejected':
        label = AppStrings.get('rejected', lang);
        break;
      default:
        label = lang == 'fr' ? 'En attente' : 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
