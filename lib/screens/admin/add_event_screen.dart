import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/admin_web/audit.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/theme/adaptive_colors.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/utils/image_upload.dart';

/// `date` text stored on an event: ISO, so the events list (ordered by
/// `date`) sorts chronologically and the calendar export can read it.
String formatEventDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// `time` text stored on an event: "09:00 - 13:00", "09:00" when there is no
/// end time, or empty for an all-day event.
String formatEventTime(TimeOfDay? start, TimeOfDay? end) {
  String f(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  if (start == null) return '';
  return end == null ? f(start) : '${f(start)} - ${f(end)}';
}

/// Admin-only form that creates an `events` document. firestore.rules only
/// lets admins write to `events`, so the entry points are shown in admin
/// mode only.
class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _description = TextEditingController();
  final _picker = ImagePicker();
  DateTime? _date;
  TimeOfDay? _start;
  TimeOfDay? _end;
  Uint8List? _photo;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  String _t(String key) => AppStrings.get(key, context.read<LanguageProvider>().lang);

  void _snack(String key) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t(key))));
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (start ? _start : _end ?? _start) ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked == null || !mounted) return;
    setState(() => start ? _start = picked : _end = picked);
  }

  Future<void> _pickPhoto() async {
    final bytes = await pickUploadImage(_picker, ImageSource.gallery);
    if (bytes == null || bytes.length > kMaxUploadImageBytes) return;
    if (mounted) setState(() => _photo = bytes);
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final location = _location.text.trim();
    if (title.isEmpty || location.isEmpty || _date == null) {
      _snack('ui_event_required');
      return;
    }
    if (_start == null && _end != null) {
      _snack('ui_event_need_start');
      return;
    }
    if (_start != null && _end != null) {
      final s = _start!.hour * 60 + _start!.minute;
      final e = _end!.hour * 60 + _end!.minute;
      if (e <= s) {
        _snack('ui_event_end_before_start');
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final ref = await FirebaseFirestore.instance.collection('events').add({
        'title': title,
        'date': formatEventDate(_date!),
        'time': formatEventTime(_start, _end),
        'location': location,
        'description': _description.text.trim(),
        'imageUrl': _photo == null ? '' : 'data:image/jpeg;base64,${base64Encode(_photo!)}',
        'createdAt': FieldValue.serverTimestamp(),
      });
      unawaited(logAdminAction(action: 'create', collection: 'events', docId: ref.id, summary: title));
      if (!mounted) return;
      _snack('ui_event_saved');
      Navigator.pop(context);
    } catch (_) {
      _snack('ui_event_save_failed');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    String t(String key) => AppStrings.get(key, lang);
    final loc = MaterialLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t('ui_event_new'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field(_title, t('ui_event_title'), Icons.event_outlined, maxLength: 120),
            const SizedBox(height: 16),
            _PickerTile(
              key: const ValueKey('event-date'),
              icon: Icons.calendar_today_outlined,
              label: t('ui_event_date'),
              value: _date == null ? null : loc.formatMediumDate(_date!),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: _PickerTile(
                  key: const ValueKey('event-start'),
                  icon: Icons.schedule_outlined,
                  label: t('ui_event_start'),
                  value: _start == null ? null : formatEventTime(_start, null),
                  onTap: () => _pickTime(start: true),
                  onClear: _start == null ? null : () => setState(() => _start = _end = null),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PickerTile(
                  key: const ValueKey('event-end'),
                  icon: Icons.schedule_outlined,
                  label: t('ui_event_end'),
                  value: _end == null ? null : formatEventTime(_end, null),
                  onTap: () => _pickTime(start: false),
                  onClear: _end == null ? null : () => setState(() => _end = null),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            _field(_location, t('location'), Icons.location_on_outlined, maxLength: 200),
            const SizedBox(height: 16),
            _field(_description, t('description'), Icons.description_outlined, maxLines: 4, maxLength: 2000),
            const SizedBox(height: 16),
            if (_photo != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(_photo!, height: 180, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 8),
            ],
            Row(children: [
              OutlinedButton.icon(
                onPressed: _saving ? null : _pickPhoto,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(t(_photo == null ? 'ui_event_add_photo' : 'ui_event_change_photo')),
              ),
              if (_photo != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _saving ? null : () => setState(() => _photo = null),
                  child: Text(t('ui_event_remove_photo')),
                ),
              ],
            ]),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const ValueKey('event-save'),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(t('ui_event_save')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon, {int maxLines = 1, int? maxLength}) => TextField(
        controller: c,
        maxLines: maxLines,
        maxLength: maxLength,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: label,
          counterText: '',
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primary, width: 2),
          ),
        ),
      );
}

/// A tappable field that shows a picked date or time.
class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _PickerTile({super.key, required this.icon, required this.label, required this.value, required this.onTap, this.onClear});

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: InputDecorator(
          isEmpty: value == null,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            suffixIcon: onClear == null ? null : IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onClear),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(value ?? '', style: TextStyle(color: context.textStrong)),
        ),
      );
}
