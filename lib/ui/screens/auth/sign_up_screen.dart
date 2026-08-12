import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../data/services/supabase/supabase_service.dart';
import '../../widgets/auth/auth_form_widget.dart' show AuthFormWidget, AuthMode;
import '../../widgets/common/motion/motion.dart';
import '../../widgets/common/theme_toggle_button.dart';
import 'sign_in_screen.dart';

/// Sign up. Mirrors the sign-in layout: cascade logo first, wordmark,
/// tagline, form, link back. Same dimensions and timing so the user
/// recognises it as the same family of screens.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  static const String routeName = 'sign-up';
  static const String routePath = '/sign-up';

  static const double _logoWidth = 200;
  static const double _logoHeight = 125;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _busy = false;

  /// With email confirmation on, sign-up returns no session and the router
  /// stays put. Without this the screen would look like nothing happened.
  Future<void> _signUp(String email, String password) async {
    final AuthResponse response = await SupabaseService.signUp(
      email: email,
      password: password,
    );
    if (response.session != null || !mounted) {
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
        child: Column(
          children: [
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
                          width: SignUpScreen._logoWidth,
                          height: SignUpScreen._logoHeight,
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
                            'Seis caracteres como mínimo. Nada más.',
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
                    AnimatedListItem(
                      index: 0,
                      child: AuthFormWidget(
                        mode: AuthMode.signUp,
                        onLoadingChanged: (busy) =>
                            setState(() => _busy = busy),
                        onSubmit: _signUp,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AnimatedListItem(
                      index: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => context.goNamed(SignInScreen.routeName),
                            child: const Text('Ya tengo una cuenta'),
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
