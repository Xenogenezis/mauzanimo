import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../lang/app_strings.dart';
import '../../models/app_notification.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/notification_text.dart';
import '../adoption/my_adoptions_screen.dart';
import '../sightings/sightings_screen.dart';

/// The signed-in user's in-app notifications, newest first.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    final signedIn = context.watch<AuthProvider>().isAuthenticated;
    final provider = context.watch<NotificationsProvider>();
    String t(String k) => AppStrings.get(k, lang);

    Widget body;
    if (!signedIn) {
      body = _Message(icon: Icons.lock_outline, title: t('notifications_login'));
    } else if (provider.hasError && provider.items.isEmpty) {
      body = _Message(icon: Icons.error_outline, title: t('notifications_error'));
    } else if (provider.isLoading && provider.items.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = NotificationsList(
        items: provider.items,
        lang: lang,
        now: DateTime.now(),
        onTap: (n) {
          provider.markRead(n);
          openNotificationTarget(context, n);
        },
        onDismissed: (n) {
          provider.delete(n);
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(t('notifications_deleted'))));
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t('notifications')),
        actions: [
          if (signedIn && provider.unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: t('notifications_mark_all_read'),
              onPressed: provider.markAllRead,
            ),
        ],
      ),
      body: body,
    );
  }
}

/// Opens the screen a notification points at.
void openNotificationTarget(BuildContext context, AppNotification n) {
  final Widget? target = switch (n.type) {
    AppNotification.typeAdoptionStage => const MyAdoptionsScreen(),
    AppNotification.typeSighting when n.refId.isNotEmpty =>
      SightingsScreen(lostReportId: n.refId),
    _ => null,
  };
  if (target == null) return;
  Navigator.push(context, MaterialPageRoute(builder: (_) => target));
}

/// Stateless list, kept apart from the provider so it can be tested with
/// fake data.
class NotificationsList extends StatelessWidget {
  final List<AppNotification> items;
  final String lang;
  final DateTime now;
  final void Function(AppNotification) onTap;
  final void Function(AppNotification) onDismissed;

  const NotificationsList({
    super.key,
    required this.items,
    required this.lang,
    required this.now,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _Message(
        icon: Icons.notifications_none,
        title: AppStrings.get('notifications_empty_title', lang),
        body: AppStrings.get('notifications_empty_body', lang),
      );
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final n = items[i];
        return Dismissible(
          key: ValueKey('notif-${n.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red.shade400,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          onDismissed: (_) => onDismissed(n),
          child: _NotificationTile(n: n, lang: lang, now: now, onTap: () => onTap(n)),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification n;
  final String lang;
  final DateTime now;
  final VoidCallback onTap;

  const _NotificationTile({required this.n, required this.lang, required this.now, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final icon = switch (n.type) {
      AppNotification.typeAdoptionStage => Icons.favorite,
      AppNotification.typeSighting => Icons.visibility,
      _ => Icons.notifications,
    };
    final unread = !n.read;
    return ListTile(
      key: ValueKey('notif-tile-${n.id}'),
      tileColor: unread ? AppTheme.primary.withValues(alpha: 0.08) : null,
      leading: CircleAvatar(
        backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
        child: Icon(icon, color: AppTheme.primary),
      ),
      title: Text(
        notificationTitle(n.type, lang),
        style: TextStyle(fontWeight: unread ? FontWeight.bold : FontWeight.normal),
      ),
      subtitle: Text(notificationBody(n.type, n.params, lang)),
      isThreeLine: true,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(notificationAge(n.createdAt, now, lang), style: Theme.of(context).textTheme.bodySmall),
          if (unread)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                key: const ValueKey('notif-unread-dot'),
                width: 10,
                height: 10,
                decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? body;

  const _Message({required this.icon, required this.title, this.body});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: muted),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(body!, textAlign: TextAlign.center, style: TextStyle(color: muted)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bell with an unread badge for the home app bar. Hidden when signed out.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    if (!context.watch<AuthProvider>().isAuthenticated) return const SizedBox.shrink();
    final lang = context.watch<LanguageProvider>().lang;
    final count = context.watch<NotificationsProvider>().unreadCount;
    return IconButton(
      tooltip: AppStrings.get('notifications', lang),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(count > 99 ? '99+' : '$count'),
        child: const Icon(Icons.notifications_outlined),
      ),
      onPressed: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
    );
  }
}
