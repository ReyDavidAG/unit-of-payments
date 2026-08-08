import 'package:flutter/material.dart';

import '../../../config/theme/app_spacing.dart';

/// One sentence and one button. No illustration, no icon balloon.
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    required this.message,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: theme.textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ),
        ],
      ),
    );
  }
}
