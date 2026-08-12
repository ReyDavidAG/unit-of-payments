import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../data/services/supabase/supabase_service.dart';
import 'password_field_widget.dart';

/// Auth mode drives validation rules and copy. Sign-in lets the server be
/// the source of truth for "incorrect" (no client-side min-length check
/// leaks the password format). Sign-up enforces the same standards Auth0
/// does for a fresh registration.
enum AuthMode { signIn, signUp }

/// Email and password form shared by sign-in and sign-up.
/// Client-side validation is a courtesy; the database is what enforces.
class AuthFormWidget extends StatefulWidget {
  const AuthFormWidget({
    required this.mode,
    required this.onSubmit,
    this.onLoadingChanged,
    super.key,
  });

  final AuthMode mode;

  /// Fires on every transition into and out of the busy state. Parents use
  /// this to disable sibling buttons (Crear cuenta, Olvidé mi contraseña)
  /// while a request is in flight.
  final ValueChanged<bool>? onLoadingChanged;

  /// Throws to signal failure. The message shown comes from
  /// [SupabaseService.describeError].
  final Future<void> Function(String email, String password) onSubmit;

  String get _submitLabel => switch (mode) {
    AuthMode.signIn => 'Iniciar sesión',
    AuthMode.signUp => 'Crear cuenta',
  };

  String get _loadingLabel => switch (mode) {
    AuthMode.signIn => 'Iniciando sesión…',
    AuthMode.signUp => 'Creando cuenta…',
  };

  @override
  State<AuthFormWidget> createState() => _AuthFormWidgetState();
}

class _AuthFormWidgetState extends State<AuthFormWidget> {
  static const double _spinnerSize = 16;
  static const int _signUpMinPasswordLength = 8;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _setLoading(bool loading) {
    if (_loading == loading) return;
    setState(() => _loading = loading);
    widget.onLoadingChanged?.call(loading);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    _setLoading(true);
    setState(() => _error = null);
    try {
      await widget.onSubmit(_email.text.trim(), _password.text);
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = SupabaseService.describeError(error));
      }
    } finally {
      if (mounted) {
        _setLoading(false);
      }
    }
  }

  String? _validateEmail(String? value) {
    final String email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Escribe tu correo.';
    }
    // Deliberately loose: the server and the inbox are the real validators.
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Eso no parece un correo.';
    }
    return null;
  }

  /// Sign-in never tells the user "this is too short" — that leaks the
  /// password format and trains them to try variations on the server.
  /// Sign-up enforces [kSignUpMinPasswordLength] to match Auth0's defaults.
  String? _validatePassword(String? value) {
    final String password = value ?? '';
    if (password.isEmpty) {
      return 'Escribe tu contraseña.';
    }
    if (widget.mode == AuthMode.signUp &&
        password.length < _signUpMinPasswordLength) {
      return 'Mínimo $_signUpMinPasswordLength caracteres.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _email,
            enabled: !_loading,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Correo'),
            validator: _validateEmail,
          ),
          const SizedBox(height: AppSpacing.sm),
          PasswordFieldWidget(
            controller: _password,
            labelText: 'Contraseña',
            enabled: !_loading,
            autofillHints: widget.mode == AuthMode.signIn
                ? const [AutofillHints.password]
                : const [AutofillHints.newPassword],
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            validator: _validatePassword,
          ),
          if (widget.mode == AuthMode.signUp) ...[
            const SizedBox(height: AppSpacing.sm),
            const _PasswordGuidanceWidget(),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox.square(
                        dimension: _spinnerSize,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(widget._loadingLabel),
                    ],
                  )
                : Text(widget._submitLabel),
          ),
        ],
      ),
    );
  }
}

/// Sign-up only. Renders the password guidance the same way [helperText]
/// would, but with room for three bullets — Auth0's documented recipe.
class _PasswordGuidanceWidget extends StatelessWidget {
  const _PasswordGuidanceWidget();

  static const List<String> _items = [
    'Mínimo 8 caracteres',
    'Combina mayúsculas, minúsculas y números',
    'Sin datos personales obvios',
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cómo crear una contraseña segura',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs2),
        for (final String item in _items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '·  ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
