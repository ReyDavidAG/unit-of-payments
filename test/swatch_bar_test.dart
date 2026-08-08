import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:unit_of_payments/config/theme/app_colors.dart';
import 'package:unit_of_payments/config/theme/app_spacing.dart';
import 'package:unit_of_payments/config/theme/app_theme.dart';
import 'package:unit_of_payments/data/models/cards/card_model.dart';
import 'package:unit_of_payments/data/models/cards/card_statement_model.dart';
import 'package:unit_of_payments/data/models/cards/card_total_model.dart';
import 'package:unit_of_payments/data/models/subscriptions/subscription_model.dart';
import 'package:unit_of_payments/ui/widgets/cards/card_tile_widget.dart';
import 'package:unit_of_payments/ui/widgets/common/swatch_card_widget.dart';
import 'package:unit_of_payments/ui/widgets/dashboard/card_total_widget.dart';
import 'package:unit_of_payments/ui/widgets/dashboard/statement_card_widget.dart';
import 'package:unit_of_payments/ui/widgets/dashboard/upcoming_charge_widget.dart';
import 'package:unit_of_payments/ui/widgets/subscriptions/subscription_tile_widget.dart';

/// A card's colour is drawn at exactly one width, on every surface that shows
/// one. It used to be 3 in two places, 6 in a third, and a brand navy in a
/// fourth — so the same card looked like four different things.
void main() {
  setUpAll(() => initializeDateFormatting('es_MX'));

  const String morado = '#7B2D9E';
  final Color swatch = AppColors.cardSwatches['morado']!;
  final DateTime today = DateTime(2026, 9, 10);

  Widget host(Widget child) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  SubscriptionModel charge({bool carded = true}) => SubscriptionModel.fromJson({
    'id': 'sub-1',
    'name': 'Spotify',
    'amount': '139.00',
    'cycle': 'monthly',
    'first_charge_date': '2026-03-15',
    'next_charge_date': '2026-09-15',
    if (carded) 'card_id': 'card-1',
    if (carded) 'card_alias': 'NU',
    if (carded) 'card_color': morado,
  });

  /// The bar is the only stretched, coloured Container in these rows.
  double barWidth(WidgetTester tester) => tester
      .widgetList<Container>(find.byType(Container))
      .firstWhere((c) => c.color != null)
      .constraints!
      .maxWidth;

  group('every card-bearing row draws the bar at one width', () {
    testWidgets('subscription row', (tester) async {
      await tester.pumpWidget(
        host(
          SubscriptionTileWidget(
            subscription: charge(),
            today: today,
            onTap: () {},
          ),
        ),
      );
      expect(barWidth(tester), AppSpacing.swatchBar);
    });

    testWidgets('card row', (tester) async {
      await tester.pumpWidget(
        host(
          CardTileWidget(
            card: const CardModel(
              id: 'card-1',
              alias: 'NU',
              brand: CardBrand.mastercard,
              color: morado,
            ),
            onTap: () {},
            onArchive: () {},
          ),
        ),
      );
      expect(barWidth(tester), AppSpacing.swatchBar);
    });

    testWidgets('summary total row', (tester) async {
      await tester.pumpWidget(
        host(
          CardTotalWidget(
            total: const CardTotalModel(
              alias: 'NU',
              color: morado,
              brand: CardBrand.mastercard,
              subscriptionCount: 2,
              monthlyTotal: 758,
            ),
            today: today,
          ),
        ),
      );
      expect(barWidth(tester), AppSpacing.swatchBar);
    });

    testWidgets('statement row', (tester) async {
      await tester.pumpWidget(
        host(
          StatementCardWidget(
            statement: CardStatementModel.fromJson({
              'card_id': 'card-1',
              'alias': 'NU',
              'color': morado,
              'opens_after': '2026-08-20',
              'closes_on': '2026-09-20',
              'due_on': '2026-10-10',
              'total_due': '758.00',
              'owed_by_others': '0',
              'yours': '758.00',
              'line_count': 2,
            }),
            today: today,
          ),
        ),
      );
      expect(barWidth(tester), AppSpacing.swatchBar);
    });
  });

  group('the colour itself is the card swatch', () {
    Color barColour(WidgetTester tester) => tester
        .widgetList<Container>(find.byType(Container))
        .firstWhere((c) => c.color != null)
        .color!;

    testWidgets('on a subscription row', (tester) async {
      await tester.pumpWidget(
        host(
          SubscriptionTileWidget(
            subscription: charge(),
            today: today,
            onTap: () {},
          ),
        ),
      );
      expect(barColour(tester), swatch);
    });

    testWidgets('and on the upcoming dot, at the same width', (tester) async {
      // This dot carried the brand accent, so every Visa was the same navy no
      // matter which of your cards it was.
      await tester.pumpWidget(
        host(UpcomingChargeWidget(subscription: charge(), today: today)),
      );
      final Container dot = tester
          .widgetList<Container>(find.byType(Container))
          .firstWhere((c) => c.decoration is BoxDecoration);
      expect((dot.decoration! as BoxDecoration).color, swatch);
      expect(dot.constraints!.maxWidth, AppSpacing.swatchBar);
    });

    testWidgets('a charge with no card gets no colour', (tester) async {
      await tester.pumpWidget(
        host(
          SubscriptionTileWidget(
            subscription: charge(carded: false),
            today: today,
            onTap: () {},
          ),
        ),
      );
      expect(barColour(tester), isNot(swatch));
    });
  });

  testWidgets('a card row fits on a narrow phone', (tester) async {
    // 320 dp is the floor. The bar and the thumbnail ring cost ~11 dp that
    // "Mastercard · •••• 6739" used to have, and it overflowed by 10.
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      host(
        CardTileWidget(
          card: const CardModel(
            id: 'card-1',
            alias: 'Mercado Pago Crédito',
            brand: CardBrand.mastercard,
            color: morado,
            last4: '6739',
          ),
          onTap: () {},
          onArchive: () {},
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    // The digits never truncate: they are the only thing separating two cards
    // of the same brand.
    expect(find.text('•••• 6739'), findsOneWidget);
  });

  testWidgets('the bar runs the full height of the row', (tester) async {
    await tester.pumpWidget(
      host(
        SubscriptionTileWidget(
          subscription: charge(),
          today: today,
          onTap: () {},
        ),
      ),
    );
    // A guessed fixed height would leave a gap once a row wraps to two lines.
    expect(
      tester.getSize(find.byType(Container).first).height,
      tester.getSize(find.byType(SwatchCardWidget)).height,
    );
  });
}
