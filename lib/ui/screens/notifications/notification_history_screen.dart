import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../data/models/notifications/notification_log_model.dart';
import '../../../data/providers/notifications/notifications_provider.dart';
import '../../../data/services/supabase/supabase_service.dart';
import '../../widgets/common/motion/motion.dart';
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
      appBar: AppBar(title: const Text('Avisos')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(notificationLogProvider);
          await ref.read(notificationLogProvider.future);
        },
        child: switch (log) {
          AsyncLoading() => const Center(child: CircularProgressIndicator()),
          AsyncError(:final error) => _Centered(
            SupabaseService.describeError(error),
            theme,
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
