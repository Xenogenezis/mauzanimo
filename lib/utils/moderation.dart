/// Content moderation helpers.
///
/// Admins hide reported content by setting `hidden: true` on the document.
/// Lists filter those out client-side, so no new queries or indexes are
/// needed (the documents are still readable, just not shown).
library;

/// Whether a Firestore document's data has been hidden by a moderator.
bool isHiddenContent(Map<String, dynamic>? data) => data?['hidden'] == true;

/// [items] without the ones whose data (read with [dataOf]) is hidden.
List<T> withoutHidden<T>(
  Iterable<T> items,
  Map<String, dynamic>? Function(T item) dataOf,
) =>
    items.where((item) => !isHiddenContent(dataOf(item))).toList();
