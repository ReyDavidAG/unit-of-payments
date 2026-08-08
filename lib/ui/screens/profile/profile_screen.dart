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
import '../../widgets/common/profile_action_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const String routeName = 'profile';
  static const String routePath = '/perfil';

  static const double _avatarSize = 96;

  /// Initial letter of the email, or '?' when no email is loaded yet.
  /// Single uppercase glyph centred in the avatar circle.
  String _avatarLetter(String email) {
    if (email.isEmpty) return '?';
    return email.substring(0, 1).toUpperCase();
  }

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

  /// Confirms the user actually wants to leave the session before calling
  /// sign-out. A destructive button next to a non-destructive one needs
  /// a guard so a stray tap doesn't end the session.
  Future<void> _confirmSignOut(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text('Vas a salir de tu cuenta en este dispositivo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.critical,
              foregroundColor: AppColors.paper,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
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
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: const [ProfileActionButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.lg,
          AppSpacing.screenPadding,
          AppSpacing.xl,
        ),
        children: [
          AnimatedHero(
            child: _IdentityHeader(
              email: email,
              avatarLetter: _avatarLetter(email),
              isDark: isDark,
            ),
          ),
          const SizedBox(height: AppSpacing.xl2),
          ...switch (profile) {
            AsyncLoading() => const [
              Center(child: CircularProgressIndicator()),
            ],
            AsyncData(value: final ProfileModel data) => _settings(
              context,
              ref,
              data,
              isDark,
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
          _AccountActions(
            onChangePassword: () => ChangePasswordView.show(context),
            onSignOut: () => _confirmSignOut(context),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  List<Widget> _settings(
    BuildContext context,
    WidgetRef ref,
    ProfileModel profile,
    bool isDark,
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
    _ThemeSelector(isDark: isDark),
  ];
}

/// Header section: big circular avatar (initial over a primary fill),
/// 'TU CUENTA' micro-label, email in title-medium, tagline in muted
/// body. The avatar is the focal element — the email is below it.
class _IdentityHeader extends StatelessWidget {
  const _IdentityHeader({
    required this.email,
    required this.avatarLetter,
    required this.isDark,
  });

  final String email;
  final String avatarLetter;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color avatarBg = isDark ? AppColors.primaryDark : AppColors.primary;
    final Color avatarFg = isDark
        ? AppColors.onPrimaryDark
        : AppColors.onPrimary;

    return Column(
      children: [
        Container(
          width: ProfileScreen._avatarSize,
          height: ProfileScreen._avatarSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: avatarBg, shape: BoxShape.circle),
          child: Text(
            avatarLetter,
            style: theme.textTheme.displayLarge?.copyWith(
              color: avatarFg,
              fontSize: 40,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'TU CUENTA',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: AppSpacing.xs2),
        Text(
          email.isEmpty ? 'Sin correo' : email,
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'A tiempo con cada cobro.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Section header: a small coloured dot plus a micro-label. The dot's
/// colour comes from the semantic palette so each section reads as
/// its own kind of thing (info / warning / critical).
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

/// Two-state theme selector (light ↔ dark). System mode is hidden in
/// the profile by design: the toggle in the tab AppBar flips light/dark,
/// and we keep the same contract here.
class _ThemeSelector extends ConsumerWidget {
  const _ThemeSelector({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeMode current =
        ref.watch(themeProvider).value ?? AppThemeMode.light;

    return SegmentedButton<AppThemeMode>(
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

/// Action buttons at the bottom of the profile: change password (warning
/// border + label) and sign out (critical full-width FilledButton). The
/// sign-out confirmation is in [_confirmSignOut] on the parent.
class _AccountActions extends StatelessWidget {
  const _AccountActions({
    required this.onChangePassword,
    required this.onSignOut,
    required this.isDark,
  });

  final VoidCallback onChangePassword;
  final VoidCallback onSignOut;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final Color warning = isDark ? AppColors.warningDark : AppColors.warning;
    final Color critical = isDark ? AppColors.criticalDark : AppColors.critical;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton(
          onPressed: onChangePassword,
          style: OutlinedButton.styleFrom(
            foregroundColor: warning,
            side: BorderSide(color: warning),
          ),
          child: const Text('Cambiar contraseña'),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: onSignOut,
          style: FilledButton.styleFrom(
            backgroundColor: critical,
            foregroundColor: AppColors.paper,
          ),
          child: const Text('Cerrar sesión'),
        ),
      ],
    );
  }
}
