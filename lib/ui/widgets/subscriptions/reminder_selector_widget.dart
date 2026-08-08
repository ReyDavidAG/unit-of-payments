import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';

/// How far ahead of a charge to notify. Mirrors the subs_reminder_rng range,
/// but offers the four values anybody actually picks instead of a 0-30 spinner.
///
/// Chips keep the vocabulary consistent with the billing-cycle picker; the
/// dropdown was a tap too many. Amber signals "alert" — it lives in its own
/// colour lane so the eye does not confuse it with the commitment colours.
class ReminderSelectorWidget extends StatelessWidget {
  const ReminderSelectorWidget({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final int value;
  final ValueChanged<int> onChanged;

  static const Map<int, String> _options = {
    0: 'Mismo día',
    1: '1 día',
    3: '3 días',
    7: '7 días',
  };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final MapEntry<int, String> option in _options.entries)
          ChoiceChip(
            label: Text(option.value),
            selected: value == option.key,
            showCheckmark: false,
            onSelected: (_) => onChanged(option.key),
            selectedColor: theme.warning,
            backgroundColor: theme.colorScheme.surface,
            labelStyle: TextStyle(
              fontFamily: 'Geist',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.4,
              // Ink clears contrast on both light and dark amber — the chip
              // fill changes hue, but both variants are bright enough that
              // dark text stays legible on them.
              color: value == option.key
                  ? AppColors.ink
                  : theme.colorScheme.onSurface,
            ),
            side: BorderSide(
              color: value == option.key
                  ? Colors.transparent
                  : theme.colorScheme.outlineVariant,
              width: AppSpacing.xs3,
            ),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}
