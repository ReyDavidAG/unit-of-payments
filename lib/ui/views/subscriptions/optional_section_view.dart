import 'package:flutter/material.dart';

import '../../../config/theme/app_motion.dart';
import '../../../config/theme/app_spacing.dart';

/// Collapsible wrapper for the rarely-touched fields (debtor, reminder).
/// Default-collapsed keeps the sheet at viewport height for the eight
/// subscriptions out of ten that do not need either, and surfaces the
/// expand affordance for the two that do.
class OptionalSectionView extends StatefulWidget {
  const OptionalSectionView({
    required this.children,
    this.initiallyExpanded = false,
    super.key,
  });

  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  State<OptionalSectionView> createState() => _OptionalSectionViewState();
}

class _OptionalSectionViewState extends State<OptionalSectionView>
    with SingleTickerProviderStateMixin {
  late bool _expanded = widget.initiallyExpanded;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: _toggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: _expanded ? 0.25 : 0,
                  duration: AppMotion.short,
                  curve: AppMotion.easeOut,
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs2),
                Text(
                  _expanded ? 'Más opciones' : 'Más opciones',
                  style: theme.textTheme.labelLarge,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: AppMotion.short,
          curve: AppMotion.easeOut,
          child: _expanded
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widget.children,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
