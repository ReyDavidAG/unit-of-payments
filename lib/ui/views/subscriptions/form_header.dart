import 'package:flutter/material.dart';

import '../../../config/theme/app_spacing.dart';
import '../../widgets/subscriptions/sheet_drag_handle_widget.dart';

/// Header of the new-charge bottom sheet: drag handle, eyebrow label with
/// an X close affordance on the right, then the screen-sized title.
class FormHeader extends StatelessWidget {
  const FormHeader({required this.isEdit, required this.onClose, super.key});

  final bool isEdit;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SheetDragHandleWidget(),
        Row(
          children: [
            Expanded(
              child: Text(
                isEdit ? 'Editar cargo' : 'Nuevo cargo',
                style: theme.textTheme.labelSmall,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 22),
              onPressed: onClose,
              color: theme.colorScheme.onSurfaceVariant,
              tooltip: 'Cerrar',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs2),
        Text('¿Qué vas a pagar?', style: theme.textTheme.titleLarge),
      ],
    );
  }
}
