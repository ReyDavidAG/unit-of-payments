import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unit_of_payments/config/theme/app_theme.dart';
import 'package:unit_of_payments/data/services/supabase/supabase_service.dart';
import 'package:unit_of_payments/ui/widgets/auth/auth_form_widget.dart';

Widget _host(Future<void> Function(String, String) onSubmit) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: AuthFormWidget(submitLabel: 'Sign in', onSubmit: onSubmit),
  ),
);

void main() {
  testWidgets('invalid input never reaches the network', (tester) async {
    bool submitted = false;
    await tester.pumpWidget(_host((_, _) async => submitted = true));

    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Enter your email.'), findsOneWidget);
    expect(find.text('At least 6 characters.'), findsOneWidget);
    expect(submitted, isFalse);
  });

  testWidgets('a failed sign-in shows the mapped message', (tester) async {
    await tester.pumpWidget(
      _host(
        (_, _) async =>
            throw const AuthException('bad', code: 'invalid_credentials'),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, 'a@b.co');
    await tester.enterText(find.byType(TextFormField).last, 'secret1');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    // The raw 'bad' from the server must not be what the user reads.
    expect(find.text('Wrong email or password.'), findsOneWidget);
  });

  test('unknown failures do not leak a raw exception at the user', () {
    expect(
      SupabaseService.describeError(Exception('socket blew up')),
      'Something went wrong. Check your connection and try again.',
    );
    // A mapped code wins over the server text.
    expect(
      SupabaseService.describeError(
        const AuthException('x', code: 'weak_password'),
      ),
      'Password is too weak. Use at least 6 characters.',
    );
  });
}
