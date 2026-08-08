import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../data/models/notifications/notification_log_model.dart';
import '../../../data/providers/notifications/notifications_provider.dart';
import '../../views/notifications/notification_debug_view.dart';
import '../../widgets/common/error_retry_widget.dart';
import '../../widgets/common/motion/motion.dart';
import '../../widgets/common/profile_action_button.dart';
import '../../widgets/common/theme_toggle_button.dart';
import '../../widgets/notifications/notification_entry_skeleton.dart';
import '../../widgets/notifications/notification_entry_widget.dart';

class NotificationHistoryScreen extends ConsumerWidget {
  const NotificationHistoryScreen({super.key});

  static const String routeName = 'notifications';
  static const String routePath = '/avisos';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<NotificationLogModel>> log = ref.watch(
      notificationLogProvider,
    );
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        // Long-press opens the reminder diagnostic. Hidden in release: it is a
        // developer's answer to "did the OS keep them", not a user feature.
        title: GestureDetector(
          onLongPress: kDebugMode
              ? () => NotificationDebugView.show(
                  context,
                  log: log.value ?? const [],
                )
              : null,
          child: const Text('Avisos'),
        ),
        actions: const [ThemeToggleButton(), ProfileActionButton()],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(notificationLogProvider);
          await ref.read(notificationLogProvider.future);
        },
        child: switch (log) {
          AsyncLoading() => ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            itemCount: 6,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSpacing.listGap),
            itemBuilder: (_, _) => const NotificationEntrySkeleton(),
          ),
          AsyncError(:final error) => ErrorRetryWidget(
            error: error,
            onRetry: () => ref.invalidate(notificationLogProvider),
          ),
          _ => _list(log.value ?? const [], theme),
        },
      ),
    );
  }

  Widget _list(List<NotificationLogModel> entries, ThemeData theme) {
    if (entries.isEmpty) {
      return _Centered(
        'Aquí aparecen los avisos que te programo antes de cada cobro.',
        theme,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.listGap),
      itemBuilder: (_, index) => AnimatedListItem(
        index: index,
        child: NotificationEntryWidget(entry: entries[index]),
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered(this.text, this.theme);

  final String text;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AppSpacing.screenPadding),
    children: [
      const SizedBox(height: AppSpacing.xl2),
      Text(text, style: theme.textTheme.bodyLarge),
    ],
  );
}
