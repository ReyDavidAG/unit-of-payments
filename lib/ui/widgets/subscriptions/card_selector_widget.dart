import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../data/models/cards/card_model.dart';

/// Which card a charge lands on. "Sin tarjeta" is a real option: the column
/// is nullable and the dashboard accounts for the leftover separately.
///
/// A row of chips instead of a dropdown: matches the billing-cycle chips,
/// shows the card's brand swatch + alias inline so the user recognises the
/// card at a glance, and removes one tap. The selected chip uses the card's
/// own swatch as its fill, so colour does the identity work — no need to
/// read the label twice.
class CardSelectorWidget extends StatelessWidget {
  const CardSelectorWidget({
    required this.cards,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final List<CardModel> cards;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _CardChip(
          label: 'Sin tarjeta',
          swatch: null,
          selected: value == null,
          theme: theme,
          onTap: () => onChanged(null),
        ),
        for (final CardModel card in cards)
          _CardChip(
            label: card.alias,
            swatch: AppColors.swatchFromHex(card.color),
            selected: card.id == value,
            theme: theme,
            onTap: () => onChanged(card.id),
          ),
      ],
    );
  }
}

class _CardChip extends StatelessWidget {
  const _CardChip({
    required this.label,
    required this.swatch,
    required this.selected,
    required this.theme,
    required this.onTap,
  });

  final String label;
  final Color? swatch;
  final bool selected;
  final ThemeData theme;
  final VoidCallback onTap;

  /// Without a swatch we fall back to ink (light) or inkDark (dark) so the
  /// chip still reads as "selected" against the surrounding paper.
  Color get _selectedFill => swatch ?? theme.colorScheme.onSurface;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
            color: selected ? _selectedFill : theme.colorScheme.surface,
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : theme.colorScheme.outlineVariant,
              width: AppSpacing.xs3,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (swatch != null) ...[
                Container(
                  width: AppSpacing.swatchBar * 2,
                  height: AppSpacing.swatchBar * 2,
                  decoration: BoxDecoration(
                    color: selected ? theme.colorScheme.surface : swatch,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Icon(
                swatch == null
                    ? Icons.do_not_disturb_on_outlined
                    : Icons.credit_card_outlined,
                size: 16,
                color: selected
                    ? theme.colorScheme.surface
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs2),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  color: selected
                      ? theme.colorScheme.surface
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
