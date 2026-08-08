import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase/supabase_service.dart';

/// Every auth event: sign-in, sign-out, token refresh.
final StreamProvider<AuthState> authStateProvider = StreamProvider<AuthState>(
  (ref) => SupabaseService.authChanges,
);

/// Seeded from the client so the first frame is not null while the stream
/// is still warming up. Everything downstream reads this, not the client.
final Provider<Session?> sessionProvider = Provider<Session?>(
  (ref) =>
      ref.watch(authStateProvider).value?.session ?? SupabaseService.session,
);

final Provider<User?> currentUserProvider = Provider<User?>(
  (ref) => ref.watch(sessionProvider)?.user,
);

/// The id every RLS-scoped query is keyed by.
final Provider<String?> currentUserIdProvider = Provider<String?>(
  (ref) => ref.watch(currentUserProvider)?.id,
);
