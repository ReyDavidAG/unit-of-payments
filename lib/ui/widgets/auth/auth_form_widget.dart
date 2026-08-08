import 'package:flutter/material.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../data/services/supabase/supabase_service.dart';

/// Email and password form shared by sign-in and sign-up.
/// Client-side validation is a courtesy; the database is what enforces.
class AuthFormWidget extends StatefulWidget {
  const AuthFormWidget({
    required this.submitLabel,
    required this.onSubmit,
    super.key,
  });

  final String submitLabel;

  /// Throws to signal failure. The message shown comes from
  /// [SupabaseService.describeError].
  final Future<void> Function(String email, String password) onSubmit;

  @override
  State<AuthFormWidget> createState() => _AuthFormWidgetState();
}

class _AuthFormWidgetState extends State<AuthFormWidget> {
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

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_email.text.trim(), _password.text);
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

  String? _validateEmail(String? value) {
    final String email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Enter your email.';
    }
    // Deliberately loose: the server and the inbox are the real validators.
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'That does not look like an email.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').length < 6) {
      return 'At least 6 characters.';
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
            decoration: const InputDecoration(labelText: 'Email'),
            validator: _validateEmail,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _password,
            enabled: !_loading,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: 'Password'),
            validator: _validatePassword,
            onFieldSubmitted: (_) => _submit(),
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
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.submitLabel),
          ),
        ],
      ),
    );
  }
}
