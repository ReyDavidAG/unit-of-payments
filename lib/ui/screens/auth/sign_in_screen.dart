import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../data/services/supabase/supabase_service.dart';
import '../../views/auth/password_reset_view.dart';
import '../../widgets/auth/auth_form_widget.dart';
import '../../widgets/common/motion/motion.dart';
import '../../widgets/common/theme_toggle_button.dart';
import 'sign_up_screen.dart';

/// Sign in. The cascade logo is the hero: three stacked payment cards
/// fading from deep aubergine to warm amber, with a thin ink mark on
/// the front card signalling "next charge". It does the brand work so
/// the typography can stay quiet.
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  static const String routeName = 'sign-in';
  static const String routePath = '/sign-in';

  static const double _logoWidth = 200;
  static const double _logoHeight = 125; // 1.6:1, matches the cascade SVG

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Theme toggle pinned to the top-right of the safe area.
            // The form below scrolls independently so the toggle stays
            // visible while the user types.
            Align(alignment: Alignment.topRight, child: ThemeToggleButton()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                  vertical: AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xl3),
                    AnimatedHero(
                      child: Center(
                        child: Image.asset(
                          'lib/assets/icon/splash.png',
                          width: _logoWidth,
                          height: _logoHeight,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AnimatedHero(
                      child: Column(
                        children: [
                          Text(
                            'Vence',
                            style: theme.textTheme.displayLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'A tiempo con cada cobro.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl2),
                    // AnimatedListItem wraps the whole form so the email +
                    // password + CTA reveal together as one logical block —
                    // email first, password second, submit last is the form's
                    // own progression.
                    AnimatedListItem(
                      index: 0,
                      child: AuthFormWidget(
                        submitLabel: 'Iniciar sesión',
                        onSubmit: (email, password) => SupabaseService.signIn(
                          email: email,
                          password: password,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AnimatedListItem(
                      index: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => PasswordResetView.show(context),
                            child: const Text('Olvidé mi contraseña'),
                          ),
                          TextButton(
                            onPressed: () =>
                                context.goNamed(SignUpScreen.routeName),
                            child: const Text('Crear cuenta'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
