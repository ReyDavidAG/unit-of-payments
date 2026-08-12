import 'package:flutter/material.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../data/services/supabase/supabase_service.dart';
import '../../widgets/auth/password_field_widget.dart';

/// Change the password of the signed-in account.
class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const ChangePasswordView(),
  );

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  static const double _spinnerSize = 16;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await SupabaseService.updatePassword(_password.text);
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada.')),
      );
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = SupabaseService.describeError(error));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Cambiar contraseña', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            PasswordFieldWidget(
              controller: _password,
              labelText: 'Nueva contraseña',
              enabled: !_loading,
              autofillHints: const [AutofillHints.newPassword],
              validator: (value) =>
                  (value ?? '').length < 6 ? 'Mínimo 6 caracteres.' : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            PasswordFieldWidget(
              controller: _confirm,
              labelText: 'Repítela',
              enabled: !_loading,
              // Confirmation exists because the field is obscured: a typo here
              // locks the account out until a reset email.
              validator: (value) =>
                  value == _password.text ? null : 'No coinciden.',
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox.square(
                          dimension: _spinnerSize,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Text('Guardando…'),
                      ],
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
