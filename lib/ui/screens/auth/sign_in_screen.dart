import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../data/services/supabase/supabase_service.dart';
import '../../widgets/auth/auth_form_widget.dart';
import 'sign_up_screen.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  static const String routeName = 'sign-in';
  static const String routePath = '/sign-in';

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
              Text('Sign in', style: theme.textTheme.headlineLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Your subscriptions follow your account across devices.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AuthFormWidget(
                submitLabel: 'Sign in',
                onSubmit: (email, password) =>
                    SupabaseService.signIn(email: email, password: password),
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => context.goNamed(SignUpScreen.routeName),
                  child: const Text('Create an account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
