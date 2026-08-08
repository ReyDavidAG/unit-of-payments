import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../data/models/profile/profile_model.dart';
import '../../../data/providers/notifications/notifications_provider.dart';
import '../../../data/providers/profile/profile_provider.dart';
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
          OutlinedButton(
            onPressed: () => ChangePasswordView.show(context),
            child: const Text('Cambiar contraseña'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: SupabaseService.signOut,
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
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
