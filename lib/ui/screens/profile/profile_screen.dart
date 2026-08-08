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
import '../../widgets/common/motion/motion.dart';
import '../../widgets/common/version_label_widget.dart';
import '../../widgets/profile/account_actions.dart';
import '../../widgets/profile/identity_header.dart';
import '../../widgets/profile/sign_out_dialog.dart';

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
      ref.invalidate(notificationSyncProvider);
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(SupabaseService.describeError(error))),
      );
    }
  }

  Future<void> _confirmSignOut(BuildContext context, String email) async {
    final bool confirmed = await showSignOutDialog(context, email: email);
    if (confirmed) {
      await SupabaseService.signOut();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<ProfileModel?> profile = ref.watch(profileProvider);
    final String email = SupabaseService.session?.user.email ?? '';
    final bool isDark = theme.brightness == Brightness.dark;
    final Color sectionDot = isDark ? AppColors.infoDark : AppColors.info;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.lg,
          AppSpacing.screenPadding,
          AppSpacing.xl,
        ),
        children: [
          AnimatedHero(child: IdentityHeader(email: email)),
          const SizedBox(height: AppSpacing.xl2),
          ...switch (profile) {
            AsyncLoading() => const [
              Center(child: CircularProgressIndicator()),
            ],
            AsyncData(value: final ProfileModel data) => _settings(
              context,
              ref,
              data,
              sectionDot,
            ),
            _ => [
              Text(
                'No pudimos cargar tus preferencias.',
                style: theme.textTheme.bodyLarge,
              ),
            ],
          },
          const SizedBox(height: AppSpacing.xl2),
          AccountActions(
            onChangePassword: () => ChangePasswordView.show(context),
            onSignOut: () => _confirmSignOut(context, email),
          ),
          const SizedBox(height: AppSpacing.lg),
          const VersionLabelWidget(),
        ],
      ),
    );
  }

  List<Widget> _settings(
    BuildContext context,
    WidgetRef ref,
    ProfileModel profile,
    Color sectionDot,
  ) => [
    _SectionHeader(label: 'PREFERENCIAS', color: sectionDot),
    const SizedBox(height: AppSpacing.sm),
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
    const SizedBox(height: AppSpacing.xl2),
    _SectionHeader(label: 'APARIENCIA', color: sectionDot),
    const SizedBox(height: AppSpacing.sm),
    _ThemeSelector(),
  ];
}

/// Section header: a small coloured dot plus a micro-label. The dot's
/// colour comes from the semantic palette so each section reads as its
/// own kind of thing (info / warning / critical).
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

/// Two-state theme selector (light ↔ dark). System mode is hidden in the
/// profile by design: the toggle in the tab AppBar flips light/dark, and
/// we keep the same contract here.
class _ThemeSelector extends ConsumerWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeMode current = ref.watch(themeProvider);

    return SegmentedButton<AppThemeMode>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment<AppThemeMode>(
          value: AppThemeMode.light,
          icon: Icon(Icons.light_mode_outlined),
          label: Text('Claro'),
        ),
        ButtonSegment<AppThemeMode>(
          value: AppThemeMode.dark,
          icon: Icon(Icons.dark_mode_outlined),
          label: Text('Oscuro'),
        ),
      ],
      selected: {
        current == AppThemeMode.dark ? AppThemeMode.dark : AppThemeMode.light,
      },
      onSelectionChanged: (selection) =>
          ref.read(themeProvider.notifier).set(selection.first),
    );
  }
}
