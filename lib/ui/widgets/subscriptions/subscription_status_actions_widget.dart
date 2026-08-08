import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../../data/models/subscriptions/subscription_model.dart';
import '../common/confirm_dialog.dart';

/// Pause / resume / cancel, at the foot of the edit sheet. Text buttons, below
/// the save action: these change what a charge *is*, so they must be findable,
/// but they must never compete with the button the user came here to press.
class SubscriptionStatusActionsWidget extends StatelessWidget {
  const SubscriptionStatusActionsWidget({
    required this.status,
    required this.onStatus,
    super.key,
  });

  final SubscriptionStatus status;
  final ValueChanged<SubscriptionStatus> onStatus;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final bool paused = status == SubscriptionStatus.paused;

    return Row(
      children: [
        Expanded(
          child: TextButton.icon(
            onPressed: () => onStatus(
              paused ? SubscriptionStatus.active : SubscriptionStatus.paused,
            ),
            icon: Icon(paused ? Icons.play_arrow : Icons.pause, size: 20),
            label: Text(paused ? 'Reanudar' : 'Pausar'),
          ),
        ),
        Expanded(
          child: TextButton.icon(
            onPressed: () => onStatus(SubscriptionStatus.cancelled),
            icon: const Icon(Icons.block, size: 20),
            label: const Text('Cancelar cargo'),
            // The one irreversible action on this sheet wears the danger hue;
            // pausing is reversible and stays in the default voice.
            style: TextButton.styleFrom(
              foregroundColor: isDark ? AppColors.dangerDark : AppColors.danger,
            ),
          ),
        ),
      ],
    );
  }
}

/// Cancelling hides the charge for good, so it asks first. Pausing does not:
/// it is one tap to undo and a dialog would only be in the way.
Future<bool> confirmCancelSubscription(BuildContext context, String name) =>
    showConfirmDialog(
      context,
      title: '¿Cancelar el cargo?',
      message:
          '$name sale de tu lista y deja de contar en tus totales. '
          'Los avisos que ya te mandé se quedan en el historial.',
      confirmLabel: 'Cancelar cargo',
      destructive: true,
    );
