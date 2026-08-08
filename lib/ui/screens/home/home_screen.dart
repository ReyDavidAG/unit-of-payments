import 'package:flutter/material.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../data/services/supabase/supabase_service.dart';

/// Placeholder destination. The dashboard replaces this in feature/dashboard.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String routeName = 'home';
  static const String routePath = '/';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? email = SupabaseService.session?.user.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unit of Payments'),
        actions: [
          IconButton(
            onPressed: SupabaseService.signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Text(
          'Signed in as ${email ?? 'unknown'}',
          style: theme.textTheme.bodyLarge,
        ),
      ),
    );
  }
}
