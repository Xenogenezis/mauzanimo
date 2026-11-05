import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';
import 'package:stray_pets_mu/models/adoption.dart';
import 'package:stray_pets_mu/providers/adoption_provider.dart';
import 'package:stray_pets_mu/providers/auth_provider.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/screens/adoption/adoption_workflow_screen.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/utils/result.dart';
import 'package:stray_pets_mu/widgets/login_required_view.dart';
import 'package:stray_pets_mu/widgets/my_adoption_card.dart';

/// The signed-in user's adoption applications and their current stage.
class MyAdoptionsScreen extends StatefulWidget {
  const MyAdoptionsScreen({super.key});

  @override
  State<MyAdoptionsScreen> createState() => _MyAdoptionsScreenState();
}

class _MyAdoptionsScreenState extends State<MyAdoptionsScreen> {
  String? _uid;
  Stream<List<Adoption>>? _stream;
  Object? _setupError;

  void _subscribe(String uid) {
    _uid = uid;
    _setupError = null;
    _stream = null;
    final result = context.read<AdoptionProvider>().adoptionsForUser(uid);
    _stream = result.dataOrNull;
    _setupError = result.errorOrNull;
  }

  void _openAdoption(Adoption adoption) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdoptionWorkflowScreen.existing(adoption: adoption),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    final uid = context.watch<AuthProvider>().uid;
    String t(String k) => AppStrings.get(k, lang);

    Widget body;
    if (uid == null) {
      _uid = null;
      _stream = null;
      body = LoginRequiredView(
        icon: Icons.volunteer_activism_outlined,
        message: t('my_adoptions_login'),
      );
    } else {
      if (uid != _uid) _subscribe(uid);
      body = StreamBuilder<List<Adoption>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (_setupError != null || snapshot.hasError) {
            final error = snapshot.error;
            if (isPermissionDenied(error)) {
              return LoginRequiredView(
                icon: Icons.volunteer_activism_outlined,
                message: t('my_adoptions_login'),
              );
            }
            return _ErrorView(
              message: t('my_adoptions_error'),
              retryLabel: t('my_adoptions_retry'),
              onRetry: () => setState(() => _subscribe(uid)),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary));
          }
          return MyAdoptionsList(
            adoptions: snapshot.data!,
            onTap: _openAdoption,
            onBrowse: () => Navigator.of(context).pop(),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(t('my_adoptions')),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: body,
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 15)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(retryLabel),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
