import 'package:flutter/material.dart';

import '../../../config/theme/app_spacing.dart';
import '../../widgets/subscriptions/owed_by_field_widget.dart';
import '../../widgets/subscriptions/reminder_selector_widget.dart';
import 'optional_section_view.dart';

/// Wraps the two rarely-touched fields (debtor, reminder) inside the
/// collapsed-by-default "Más opciones" section. The form view hands it the
/// controllers and callbacks; this view owns the layout and labels.
class FormOptionalSection extends StatelessWidget {
  const FormOptionalSection({
    required this.owedByController,
    required this.reminderDays,
    required this.onReminderChanged,
    super.key,
  });

  final TextEditingController owedByController;
  final int reminderDays;
  final ValueChanged<int> onReminderChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return OptionalSectionView(
      children: [
        OwedByFieldWidget(controller: owedByController),
        const SizedBox(height: AppSpacing.md),
        Text('Avisarme', style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        ReminderSelectorWidget(
          value: reminderDays,
          onChanged: onReminderChanged,
        ),
      ],
    );
  }
}
