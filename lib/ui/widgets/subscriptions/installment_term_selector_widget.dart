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

  /// Paid once, settled on the next statement. A plan of length one, so it
  /// needs no separate kind, trigger or progress maths — only its own chip,
  /// because "1 MSI" is not a thing anybody says.
  static const int contado = 1;

  static const List<int> terms = [3, 6, 9, 12, 18, 24];

  /// Far and away the most common promotion, so it costs the user no taps.
  static const int defaultTerm = 12;

  /// A count that has its own chip, so the free-text field stays closed.
  static bool isPreset(int count) => count == contado || terms.contains(count);

  /// Mirrors subs_installments. Contado has a chip, so a count typed by hand
  /// is always a real term.
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
            // First, and with its own glyph: it is the one option here that
            // does not spread the charge over months.
            _PromoChip(
              icon: Icons.bolt_outlined,
              label: 'Contado',
              selected: !isCustom && term == contado,
              theme: theme,
              onSelected: () => onTerm(contado),
            ),
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
        color: selected ? theme.info : theme.colorScheme.onSurfaceVariant,
      ),
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onSelected(),
      // A solid info fill left the label at 3.55:1 in light mode, and no token
      // cleared 4.5 on top of it. The 15% wash is the grammar every other chip
      // and segment already speaks; info instead of primary keeps the MSI lane.
      selectedColor: theme.info.withValues(alpha: 0.15),
      backgroundColor: theme.colorScheme.surface,
      labelStyle: (theme.textTheme.labelLarge ?? const TextStyle()).copyWith(
        color: theme.colorScheme.onSurface,
      ),
      side: BorderSide(
        color: selected ? theme.info : theme.colorScheme.outlineVariant,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}
