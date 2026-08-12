import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/helpers/money_helper.dart';
import '../../../data/models/charge_history/charge_history_entry.dart';
import '../../../data/providers/charge_history/charge_history_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_retry_widget.dart';
import '../../widgets/common/motion/motion.dart';
import '../../widgets/common/swatch_card_widget.dart';

/// Past charges, derived from each subscription's first charge date and
/// cycle. Read-only — the app does not track payments, only reminders,
/// so "realizado" here means "the charge date is in the past".
class ChargeHistoryScreen extends ConsumerWidget {
  const ChargeHistoryScreen({super.key});

  static const String routeName = 'charge-history';
  static const String routePath = '/historial';

  static final DateFormat _monthHeader = DateFormat('MMMM y', 'es_MX');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ChargeHistoryEntry>> async = ref.watch(
      chargeHistoryProvider,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: async.when(
        loading: () => const _LoadingList(),
        error: (error, _) => ErrorRetryWidget(
          error: error,
          onRetry: () => ref.invalidate(chargeHistoryProvider),
        ),
        data: (entries) => entries.isEmpty
            ? EmptyStateWidget(
                message: 'Aún no tienes cobros registrados.',
                actionLabel: 'Volver',
                onAction: () => Navigator.of(context).pop(),
              )
            : _GroupedList(entries: entries),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: 8,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.listGap),
      itemBuilder: (_, _) => const _RowSkeleton(),
    );
  }
}

class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
    );
  }
}

class _GroupedList extends StatelessWidget {
  const _GroupedList({required this.entries});

  final List<ChargeHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    // Entries arrive sorted desc by date; group by (year, month) preserving
    // that order so the newest month appears first.
    final List<List<ChargeHistoryEntry>> groups = [];
    final List<String> headers = [];
    for (final ChargeHistoryEntry entry in entries) {
      final String header = ChargeHistoryScreen._monthHeader
          .format(entry.chargeDate)
          .replaceFirstMapped(
            RegExp(r'^.'),
            (Match m) => m.group(0)!.toUpperCase(),
          );
      if (groups.isEmpty || headers.last != header) {
        headers.add(header);
        groups.add([entry]);
      } else {
        groups.last.add(entry);
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        AppSpacing.xl,
      ),
      itemCount: groups.length,
      itemBuilder: (BuildContext context, int g) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(label: headers[g]),
              const SizedBox(height: AppSpacing.sm),
              for (int i = 0; i < groups[g].length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i == groups[g].length - 1 ? 0 : AppSpacing.listGap,
                  ),
                  child: AnimatedListItem(
                    index: i,
                    child: _ChargeRow(entry: groups[g][i]),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: theme.colorScheme.outline,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

class _ChargeRow extends StatelessWidget {
  const _ChargeRow({required this.entry});

  final ChargeHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SwatchCardWidget(
      // The bar carries the card identity. A subscription with no card
      // uses the divider colour, the same fallback the active list uses.
      swatch: entry.cardColor == null
          ? theme.dividerColor
          : AppColors.swatchFromHex(entry.cardColor),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.subscriptionName,
                  style: theme.textTheme.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs3),
                Text(
                  [
                    MoneyHelper.shortDate(entry.chargeDate),
                    if (entry.cardAlias != null) entry.cardAlias!,
                  ].join(' · '),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            MoneyHelper.amount(entry.amount),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
