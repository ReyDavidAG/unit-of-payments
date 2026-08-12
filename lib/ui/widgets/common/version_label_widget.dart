import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_colors.dart';
import '../../../core/constants/app_version.dart';
import '../../../data/providers/version/app_version_provider.dart';

/// Which build is on this phone. Quiet on purpose — it is for whoever is
/// testing, and it must never read as something the user has to act on.
///
/// `neutral` rather than `muted`: at 3.61:1 it is deliberately the faintest
/// text in the app, and it earns that by being the one string nobody needs.
class VersionLabelWidget extends ConsumerWidget {
  const VersionLabelWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<AppVersion> asyncVersion = ref.watch(appVersionProvider);
    final String text = switch (asyncVersion) {
      AsyncData(value: final AppVersion v) => v.label,
      _ => '—',
    };
    return Text(
      text,
      textAlign: TextAlign.center,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.brightness == Brightness.dark
            ? AppColors.neutralDark
            : AppColors.neutral,
      ),
    );
  }
}
