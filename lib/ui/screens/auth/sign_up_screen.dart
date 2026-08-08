import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../data/services/supabase/supabase_service.dart';
import '../../widgets/auth/auth_form_widget.dart';
import '../../widgets/common/motion/motion.dart';
import 'sign_in_screen.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  static const String routeName = 'sign-up';
  static const String routePath = '/sign-up';

  /// With email confirmation on, sign-up returns no session and the router
  /// stays put. Without this the screen would look like nothing happened.
  Future<void> _signUp(
    BuildContext context,
    String email,
    String password,
  ) async {
    final AuthResponse response = await SupabaseService.signUp(
      email: email,
      password: password,
    );
    if (response.session != null || !context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Revisa tu correo para confirmar tu cuenta.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl2),
              AnimatedHero(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Crear cuenta', style: theme.textTheme.headlineLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Seis caracteres como mínimo. Nada más.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AuthFormWidget(
                submitLabel: 'Crear cuenta',
                onSubmit: (email, password) =>
                    _signUp(context, email, password),
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => context.goNamed(SignInScreen.routeName),
                  child: const Text('Ya tengo una cuenta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
