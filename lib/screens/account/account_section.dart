import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/repositories/account_repository.dart';
import 'package:stray_pets_mu/screens/auth/login_screen.dart';
import 'package:stray_pets_mu/screens/info/privacy_screen.dart';
import 'package:stray_pets_mu/theme/adaptive_colors.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/utils/account_data.dart';
import 'package:stray_pets_mu/utils/data_export_share.dart';
import 'package:stray_pets_mu/utils/poster_export.dart' show shareOriginOf;
import 'package:stray_pets_mu/utils/result.dart';

/// Profile > "Account & privacy": download data, privacy policy, delete.
class AccountSection extends StatefulWidget {
  final AccountRepository? repository;

  const AccountSection({super.key, this.repository});

  @override
  State<AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends State<AccountSection> {
  late final AccountRepository _repo = widget.repository ?? AccountRepository();
  bool _busy = false;

  String _t(String key) => AppStrings.get(key, context.read<LanguageProvider>().lang);

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _download(BuildContext tileContext) async {
    final uid = _repo.currentUser?.uid;
    if (uid == null || _busy) return;
    final origin = shareOriginOf(tileContext);
    setState(() => _busy = true);
    _snack(_t('acct_exporting'));
    try {
      final result = await _repo.exportOwnData(uid);
      final data = result.dataOrNull;
      if (data == null) {
        _snack(_t('acct_export_failed'));
        return;
      }
      final outcome = await shareJsonExport(
        json: encodeAccountExport(data),
        fileName: accountExportFileName(DateTime.now()),
        shareText: _t('acct_export_share_text'),
        shareOrigin: origin,
      );
      if (outcome == DataExportResult.downloaded) _snack(_t('acct_export_downloaded'));
    } catch (_) {
      _snack(_t('acct_export_failed'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final user = _repo.currentUser;
    if (user == null || _busy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _ConfirmDeleteDialog(),
    );
    if (confirmed != true || !mounted) return;

    final method = _repo.reauthMethod;
    if (method == ReauthMethod.unsupported) {
      _snack(_t('acct_unsupported_method'));
      return;
    }
    final reauthed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ReauthDialog(repository: _repo, method: method),
    );
    if (reauthed != true || !mounted) return;

    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(content: Text(_t('acct_deleting'))));
    final deletedMsg = _t('acct_deleted');
    final failedMsg = _t('acct_delete_failed');

    final dataResult = await _repo.deleteOwnData(user.uid);
    final authResult = dataResult.isSuccess
        ? await _repo.deleteAuthUser()
        : Result<void>.failure(dataResult.errorOrNull ?? 'failed');
    if (authResult.isFailure) {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(failedMsg)));
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(deletedMsg)));
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    String t(String k) => AppStrings.get(k, lang);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t('acct_section_title'),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textStrong)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: context.cardBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Column(children: [
            Builder(
              builder: (tileContext) => ListTile(
                key: const Key('acct_download'),
                enabled: !_busy,
                leading: const Icon(Icons.download_outlined, color: AppTheme.primary),
                title: Text(t('acct_download')),
                subtitle: Text(t('acct_download_sub')),
                onTap: () => _download(tileContext),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              key: const Key('acct_privacy'),
              leading: const Icon(Icons.privacy_tip_outlined, color: AppTheme.primary),
              title: Text(t('acct_privacy')),
              subtitle: Text(t('acct_privacy_sub')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const PrivacyScreen())),
            ),
            const Divider(height: 1),
            ListTile(
              key: const Key('acct_delete'),
              enabled: !_busy,
              leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
              title: Text(t('acct_delete'), style: const TextStyle(color: Colors.red)),
              subtitle: Text(t('acct_delete_sub')),
              onTap: _delete,
            ),
          ]),
        ),
      ],
    );
  }
}

/// Step 1+2: explain what is deleted/kept, then require typing DELETE.
class _ConfirmDeleteDialog extends StatefulWidget {
  const _ConfirmDeleteDialog();

  @override
  State<_ConfirmDeleteDialog> createState() => _ConfirmDeleteDialogState();
}

class _ConfirmDeleteDialogState extends State<_ConfirmDeleteDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    String t(String k) => AppStrings.get(k, lang);
    final ok = isDeleteConfirmation(_controller.text);
    return AlertDialog(
      title: Text(t('acct_delete_title')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t('acct_delete_explain')),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(t('acct_delete_kept'), style: const TextStyle(fontSize: 13)),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('acct_delete_confirm_field'),
              controller: _controller,
              autocorrect: false,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: t('acct_type_delete'),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false), child: Text(t('acct_cancel'))),
        TextButton(
          key: const Key('acct_delete_continue'),
          onPressed: ok ? () => Navigator.pop(context, true) : null,
          child: Text(t('acct_continue'), style: TextStyle(color: ok ? Colors.red : null)),
        ),
      ],
    );
  }
}

/// Step 3: re-authenticate (password, or Google provider flow).
class _ReauthDialog extends StatefulWidget {
  final AccountRepository repository;
  final ReauthMethod method;

  const _ReauthDialog({required this.repository, required this.method});

  @override
  State<_ReauthDialog> createState() => _ReauthDialogState();
}

class _ReauthDialogState extends State<_ReauthDialog> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final lang = context.read<LanguageProvider>().lang;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await widget.repository.reauthenticate(
        password: widget.method == ReauthMethod.password ? _password.text : null);
    if (!mounted) return;
    if (result.isSuccess) {
      Navigator.pop(context, true);
      return;
    }
    final code = result.errorOrNull;
    setState(() {
      _busy = false;
      _error = AppStrings.get(
          code == 'wrong-password' || code == 'invalid-credential'
              ? 'acct_wrong_password'
              : 'acct_reauth_failed',
          lang);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    String t(String k) => AppStrings.get(k, lang);
    final isPassword = widget.method == ReauthMethod.password;
    return AlertDialog(
      title: Text(t('acct_reauth_title')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t(isPassword ? 'acct_reauth_password_body' : 'acct_reauth_google_body')),
          if (isPassword) ...[
            const SizedBox(height: 12),
            TextField(
              key: const Key('acct_reauth_password'),
              controller: _password,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                labelText: t('acct_password'),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _busy ? null : _submit(),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],
        ],
      ),
      actions: [
        TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context, false),
            child: Text(t('acct_cancel'))),
        TextButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(isPassword ? t('acct_continue') : t('acct_reauth_google_button'),
                  style: const TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
