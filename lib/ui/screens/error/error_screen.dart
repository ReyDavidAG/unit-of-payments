import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../config/router/app_router.dart';

/// Single screen for any go_router failure: unknown location, redirect
/// loop, or an exception thrown during navigation. The cascade logo +
/// ink-filled CTA keep the brand present so a "page not found" still
/// reads as part of Vence, not a system error page.
class ErrorScreen extends StatelessWidget {
  const ErrorScreen({this.error, super.key});

  final Exception? error;

  /// True when the error looks like a missing route (URL the user typed,
  /// or a stale link). Otherwise the message is treated as a real failure.
  bool get _isNotFound {
    final String message = error?.toString() ?? '';
    return message.contains('no routes') ||
        message.contains('not found') ||
        message.contains('unknown route');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isNotFound = _isNotFound;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Image.asset(
                  'lib/assets/icon/splash.png',
                  width: 140,
                  height: 88, // 1.6:1, matches the cascade source
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                isNotFound ? 'No encontramos esa página' : 'Algo no salió bien',
                style: theme.textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                isNotFound
                    ? 'Revisa la URL o usa el menú para volver al inicio.'
                    : 'Vuelve a intentarlo. Si sigue fallando, '
                          'cierra y abre la app de nuevo.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              if (error != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _ErrorDetails(message: error.toString()),
              ],
              const Spacer(),
              FilledButton(
                onPressed: () {
                  // Reset to a known location. context.go replaces the
                  // current page, which clears the error state.
                  GoRouter.of(context).go(AppRouter.shellPath);
                },
                child: const Text('Volver al inicio'),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

/// Subtle mono-style panel that surfaces the exception text without
/// shouting. Useful while debugging, harmless in production because the
/// go_router errors are already short and not user-facing secrets.
class _ErrorDetails extends StatelessWidget {
  const _ErrorDetails({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
    );
  }
}
