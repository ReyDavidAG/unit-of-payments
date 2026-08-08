import 'package:flutter/material.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../data/services/supabase/supabase_service.dart';

/// What a screen shows when its data could not be read. One sentence and one
/// button, same voice as the empty state — a failure is not a reason to shout.
///
/// Owns the error-to-Spanish translation so no screen repeats it, and scrolls
/// so it still works as a `RefreshIndicator` child: a fixed-height child makes
/// pull-to-refresh impossible at exactly the moment it is wanted.
class ErrorRetryWidget extends StatelessWidget {
  const ErrorRetryWidget({
    required this.error,
    required this.onRetry,
    super.key,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        const SizedBox(height: AppSpacing.xl2),
        Text(
          SupabaseService.describeError(error),
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ),
      ],
    );
  }
}
