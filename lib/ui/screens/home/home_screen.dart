import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../data/providers/auth/auth_provider.dart';
import '../../../data/services/supabase/supabase_service.dart';

/// Placeholder destination. The dashboard replaces this in feature/dashboard.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const String routeName = 'home';
  static const String routePath = '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final User? user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unit of Payments'),
        actions: [
          IconButton(
            onPressed: SupabaseService.signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Text(
          'Sesión iniciada como ${user?.email ?? 'desconocido'}',
          style: theme.textTheme.bodyLarge,
        ),
      ),
    );
  }
}
