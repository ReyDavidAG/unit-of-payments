import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unit_of_payments/ui/widgets/common/error_retry_widget.dart';

void main() {
  Future<void> pump(WidgetTester tester, Object error, VoidCallback onRetry) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorRetryWidget(error: error, onRetry: onRetry),
          ),
        ),
      );

  testWidgets('translates the failure instead of leaking it', (tester) async {
    await pump(
      tester,
      const PostgrestException(
        message:
            'there is no unique or exclusion constraint matching '
            'the ON CONFLICT specification',
        code: '42P10',
      ),
      () {},
    );

    // Whatever the copy is, a Postgres error code must never reach the user.
    expect(find.textContaining('42P10'), findsNothing);
    expect(find.textContaining('ON CONFLICT'), findsNothing);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('retries when the button is tapped', (tester) async {
    var retries = 0;
    await pump(tester, Exception('boom'), () => retries++);

    await tester.tap(find.text('Reintentar'));
    expect(retries, 1);
  });

  testWidgets('scrolls, so pull-to-refresh still works around it', (
    tester,
  ) async {
    var refreshed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RefreshIndicator(
            onRefresh: () async => refreshed++,
            child: ErrorRetryWidget(error: Exception('boom'), onRetry: () {}),
          ),
        ),
      ),
    );

    // A fixed-height error view would silently disable the gesture at exactly
    // the moment the user wants it.
    await tester.fling(find.byType(Scrollable), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();
    expect(refreshed, 1);
  });
}
