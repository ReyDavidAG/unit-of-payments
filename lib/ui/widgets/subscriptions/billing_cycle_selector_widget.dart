import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../data/models/subscriptions/subscription_model.dart';

/// How often an open-ended subscription is charged, carrying its own period
/// field for the custom cycle. Installment plans never show this: the database
/// only accepts them as monthly.
///
/// Colour follows the form's primary lane (terracotta in light, blue in dark)
/// — `theme.colorScheme.primary` is the only colour that needs to flip, the
/// rest (`onPrimary`, `outlineVariant`, `surface`) are already theme-aware.
class BillingCycleSelectorWidget extends StatelessWidget {
  const BillingCycleSelectorWidget({
    required this.value,
    required this.onChanged,
    required this.controller,
    super.key,
  });

  final BillingCycle value;
  final ValueChanged<BillingCycle> onChanged;

  /// Holds the period while the custom cycle is active.
  final TextEditingController controller;

  /// Mirrors subs_custom_days, so the error arrives before the round trip.
  static String? validate(String? value) {
    final int? days = int.tryParse(value ?? '');
    return (days != null && days >= 1 && days <= 365)
        ? null
        : 'Entre 1 y 365 días.';
  }

  static IconData _iconFor(BillingCycle cycle) => switch (cycle) {
    BillingCycle.weekly => Icons.calendar_view_week_outlined,
    BillingCycle.monthly => Icons.calendar_view_month_outlined,
    BillingCycle.yearly => Icons.event_outlined,
    BillingCycle.custom => Icons.tune_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final BillingCycle cycle in BillingCycle.values)
              ChoiceChip(
                avatar: Icon(
                  _iconFor(cycle),
                  size: 18,
                  color: cycle == value
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                label: Text(cycle.label),
                selected: cycle == value,
                showCheckmark: false,
                onSelected: (_) => onChanged(cycle),
                selectedColor: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.surface,
                labelStyle: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  color: cycle == value
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                ),
                side: BorderSide(
                  color: cycle == value
                      ? Colors.transparent
                      : theme.colorScheme.outlineVariant,
                  width: AppSpacing.xs3,
                ),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        if (value == BillingCycle.custom) ...[
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Cada X días'),
            validator: validate,
          ),
        ],
      ],
    );
  }
}
