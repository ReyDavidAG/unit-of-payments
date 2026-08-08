import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';

/// How many months the promotion runs for. Mexican interest-free offers come in
/// fixed terms, so this is a pick, not a number to type — with the same "Otro"
/// escape the custom billing cycle already uses, because department stores do
/// run odd ones like 13 or 15.
///
/// MSI lives in its own colour lane (the semantic info blue) so the user can
/// see at a glance which section they're in. The blue flips to its dark-mode
/// variant through the [SemanticPalette] extension.
class InstallmentTermSelectorWidget extends StatelessWidget {
  const InstallmentTermSelectorWidget({
    required this.term,
    required this.isCustom,
    required this.onTerm,
    required this.controller,
    this.breakdown,
    super.key,
  });

  /// The picked term, or null while "Otro" is active.
  final int? term;
  final bool isCustom;

  /// Receives the term, or null when the user picks "Otro".
  final ValueChanged<int?> onTerm;

  /// Holds the count while "Otro" is active.
  final TextEditingController controller;

  /// What the promotion resolves to, once both numbers are real.
  final String? breakdown;

  static const List<int> terms = [3, 6, 9, 12, 18, 24];

  /// Mirrors subs_installments, so the error arrives before the round trip.
  static String? validate(String? value) {
    final int? count = int.tryParse(value ?? '');
    return (count != null && count >= 2 && count <= 60)
        ? null
        : 'Entre 2 y 60 pagos.';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Plazo', style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final int months in terms)
              _PromoChip(
                icon: Icons.credit_card_outlined,
                label: '$months MSI',
                selected: !isCustom && months == term,
                theme: theme,
                onSelected: () => onTerm(months),
              ),
            _PromoChip(
              icon: Icons.tune_outlined,
              label: 'Otro',
              selected: isCustom,
              theme: theme,
              onSelected: () => onTerm(null),
            ),
          ],
        ),
        if (isCustom) ...[
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLength: 2,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Número de pagos',
              counterText: '',
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                borderSide: BorderSide(color: theme.info, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                borderSide: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            validator: validate,
          ),
        ],
        if (breakdown != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(breakdown!, style: theme.textTheme.bodyLarge),
        ],
      ],
    );
  }
}

class _PromoChip extends StatelessWidget {
  const _PromoChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.theme,
    required this.onSelected,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final ThemeData theme;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 18,
        color: selected
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurfaceVariant,
      ),
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onSelected(),
      selectedColor: theme.info,
      backgroundColor: theme.colorScheme.surface,
      labelStyle: TextStyle(
        fontFamily: 'Geist',
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: selected
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface,
      ),
      side: BorderSide(
        color: selected ? Colors.transparent : theme.colorScheme.outlineVariant,
        width: AppSpacing.xs3,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}
