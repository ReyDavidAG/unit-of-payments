import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';

/// Who repays this charge, when the card was lent or the plan is split. Free
/// text because the database groups debtors by exactly this string.
///
/// Amber focus keeps it visually tied to the reminder chips below, so the
/// two "Más opciones" fields read as one section rather than three loose ones.
class OwedByFieldWidget extends StatelessWidget {
  const OwedByFieldWidget({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      maxLength: 40,
      decoration: InputDecoration(
        labelText: 'Te lo reembolsa',
        hintText: 'Nadie',
        helperText: 'Opcional, si prestaste la tarjeta',
        counterText: '',
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
          borderSide: BorderSide(color: theme.warning, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
          borderSide: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
    );
  }
}
