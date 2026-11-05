import '../lang/app_strings.dart';
import '../models/app_notification.dart';

/// Pure helpers that turn a stored notification (type + params) into text
/// in the reader's language.

const List<String> kNotifyStages = [
  'application', 'screening', 'meet_greet', 'trial', 'completed', 'rejected',
];

String notificationTitle(String type, String lang) => switch (type) {
      AppNotification.typeAdoptionStage => AppStrings.get('notify_title_adoption_stage', lang),
      AppNotification.typeSighting => AppStrings.get('notify_title_sighting', lang),
      _ => AppStrings.get('notify_title_generic', lang),
    };

String notificationBody(String type, Map<String, String> params, String lang) {
  switch (type) {
    case AppNotification.typeAdoptionStage:
      final stage = params['stage'] ?? '';
      final key = kNotifyStages.contains(stage)
          ? 'notify_adoption_stage_$stage'
          : 'notify_adoption_stage_other';
      final pet = (params['petName'] ?? '').trim();
      return AppStrings.get(key, lang)
          .replaceAll('{pet}', pet.isEmpty ? AppStrings.get('notify_unknown_pet', lang) : pet);
    case AppNotification.typeSighting:
      return AppStrings.get('notify_sighting_body', lang)
          .replaceAll('{animal}', _animal(params['animalType'], lang));
    default:
      return AppStrings.get('notify_body_generic', lang);
  }
}

String _animal(String? type, String lang) {
  final key = switch ((type ?? '').toLowerCase()) {
    'dog' => 'notify_animal_dog',
    'cat' => 'notify_animal_cat',
    _ => 'notify_animal_other',
  };
  return AppStrings.get(key, lang);
}

/// Short relative age, e.g. "5 min ago". Null (pending server time) is "just now".
String notificationAge(DateTime? at, DateTime now, String lang) {
  if (at == null) return AppStrings.get('notify_just_now', lang);
  final d = now.difference(at);
  String fmt(String key, int n) => AppStrings.get(key, lang).replaceAll('{n}', '$n');
  if (d.inMinutes < 1) return AppStrings.get('notify_just_now', lang);
  if (d.inHours < 1) return fmt('notify_minutes_ago', d.inMinutes);
  if (d.inDays < 1) return fmt('notify_hours_ago', d.inHours);
  return fmt('notify_days_ago', d.inDays);
}
