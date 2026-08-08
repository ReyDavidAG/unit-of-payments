import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/theme_mode_enum.dart';
import '../../../data/models/profile/profile_model.dart';
import '../../../data/providers/notifications/notifications_provider.dart';
import '../../../data/providers/profile/profile_provider.dart';
import '../../../data/providers/theme/theme_provider.dart';
import '../../../data/services/supabase/supabase_service.dart';
import '../../views/profile/change_password_view.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const String routeName = 'profile';
  static const String routePath = '/perfil';

  Future<void> _update(
    BuildContext context,
    WidgetRef ref,
    ProfileModel next,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(profileProvider.notifier).save(next);
      // The zone decides when a reminder fires, so changing it invalidates
      // every notification already scheduled.
      ref.invalidate(notificationSyncProvider);
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(SupabaseService.describeError(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<ProfileModel?> profile = ref.watch(profileProvider);
    final String email = SupabaseService.session?.user.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          Text(email, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sectionGap),
          ...switch (profile) {
            AsyncLoading() => const [
              Center(child: CircularProgressIndicator()),
            ],
            AsyncData(value: final ProfileModel data) => _settings(
              context,
              ref,
              data,
            ),
            _ => [
              Text(
                'No pudimos cargar tus preferencias.',
                style: theme.textTheme.bodyLarge,
              ),
            ],
          },
          const SizedBox(height: AppSpacing.sectionGap),
          const _ThemeSelector(),
          const SizedBox(height: AppSpacing.sectionGap),
          // Each button in the profile carries a semantic colour:
          //   info      → neutral, preference-style (theme selector tint)
          //   warning   → pay attention (changing a credential)
          //   critical  → act now / destructive (signing out)
          // The label colour alone was too quiet before; the colours now
          // signal what kind of action each button represents.
          OutlinedButton(
            onPressed: () => ChangePasswordView.show(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.brightness == Brightness.dark
                  ? AppColors.warningDark
                  : AppColors.warning,
              side: BorderSide(
                color: theme.brightness == Brightness.dark
                    ? AppColors.warningDark
                    : AppColors.warning,
              ),
            ),
            child: const Text('Cambiar contraseña'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: SupabaseService.signOut,
            style: TextButton.styleFrom(
              foregroundColor: theme.brightness == Brightness.dark
                  ? AppColors.criticalDark
                  : AppColors.critical,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  List<Widget> _settings(
    BuildContext context,
    WidgetRef ref,
    ProfileModel profile,
  ) => [
    DropdownButtonFormField<String>(
      initialValue: SupportedCurrency.fromCode(profile.currency).code,
      decoration: const InputDecoration(labelText: 'Moneda'),
      items: [
        for (final SupportedCurrency currency in SupportedCurrency.values)
          DropdownMenuItem<String>(
            value: currency.code,
            child: Text('${currency.label} (${currency.symbol})'),
          ),
      ],
      onChanged: (code) => code == null
          ? null
          : _update(context, ref, profile.copyWith(currency: code)),
    ),
    const SizedBox(height: AppSpacing.md),
    DropdownButtonFormField<String>(
      initialValue:
          supportedTimezones.any((zone) => zone.id == profile.timezone)
          ? profile.timezone
          : ProfileModel.defaultTimezone,
      decoration: const InputDecoration(
        labelText: 'Zona horaria',
        helperText: 'Decide a qué hora suenan los avisos',
      ),
      items: [
        for (final ({String id, String label}) zone in supportedTimezones)
          DropdownMenuItem<String>(value: zone.id, child: Text(zone.label)),
      ],
      onChanged: (id) => id == null
          ? null
          : _update(context, ref, profile.copyWith(timezone: id)),
    ),
  ];
}

/// Theme is device-local, so it sits apart from the profile settings that
/// travel with the account. The small info-coloured dot on the label
/// signals 'preference / state' rather than 'action' — info from the
/// semantic palette, not the terracotta accent or teal primary.
class _ThemeSelector extends ConsumerWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppThemeMode current =
        ref.watch(themeProvider).value ?? AppThemeMode.system;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color dotColor = isDark ? AppColors.infoDark : AppColors.info;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text('TEMA', style: theme.textTheme.labelSmall),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<AppThemeMode>(
          segments: [
            for (final AppThemeMode mode in AppThemeMode.values)
              ButtonSegment<AppThemeMode>(value: mode, label: Text(mode.label)),
          ],
          selected: {current},
          showSelectedIcon: false,
          onSelectionChanged: (selection) =>
              ref.read(themeProvider.notifier).set(selection.first),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(current.description, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
