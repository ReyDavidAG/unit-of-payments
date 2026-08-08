import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:unit_of_payments/config/theme/app_colors.dart';
import 'package:unit_of_payments/config/theme/app_theme.dart';
import 'package:unit_of_payments/core/helpers/commitment_summary.dart';
import 'package:unit_of_payments/data/models/subscriptions/subscription_model.dart';
import 'package:unit_of_payments/ui/widgets/common/warning_dot_widget.dart';
import 'package:unit_of_payments/ui/widgets/subscriptions/installment_term_selector_widget.dart';
import 'package:unit_of_payments/ui/widgets/subscriptions/subscription_tile_widget.dart';

void main() {
  // MoneyHelper formats dates in es_MX; main() does this before runApp.
  setUpAll(() => initializeDateFormatting('es_MX'));

  Map<String, dynamic> row(Map<String, dynamic> overrides) => {
    'id': 'sub-1',
    'name': 'Refrigerador',
    'amount': '1000.00',
    'cycle': 'monthly',
    'first_charge_date': '2026-03-15',
    'next_charge_date': '2026-09-15',
    'card_id': 'card-1',
    'card_alias': 'NU',
    'card_brand': 'mastercard',
    'card_color': '#7B2D9E',
    ...overrides,
  };

  group('SubscriptionStatus', () {
    test('reads the three states, and defaults instead of throwing', () {
      expect(
        SubscriptionModel.fromJson(row({'status': 'paused'})).status,
        SubscriptionStatus.paused,
      );
      expect(SubscriptionModel.fromJson(row({})).isPaused, isFalse);
      // A row written by a newer client must not take the list down.
      expect(
        SubscriptionModel.fromJson(row({'status': 'hibernating'})).status,
        SubscriptionStatus.active,
      );
    });

    test('status is not written back by the form', () {
      // Editing a paused charge saves name and amount, never a silent resume:
      // that transition belongs to the pause button alone.
      final SubscriptionModel paused = SubscriptionModel.fromJson(
        row({'status': 'paused'}),
      );
      expect(paused.toWrite().containsKey('status'), isFalse);
    });
  });

  group('contado', () {
    SubscriptionModel cash() => SubscriptionModel.fromJson(
      row({
        'kind': 'installment',
        'installments_total': 1,
        'installments_paid': 1,
        'installments_left': 0,
        'outstanding': '0',
      }),
    );

    test('is an installment plan of length one', () {
      expect(cash().isSingleCharge, isTrue);
      expect(cash().isInstallment, isTrue);
      expect(cash().toWrite()['installments_total'], 1);
    });

    test('a twelve-month plan is not contado', () {
      final SubscriptionModel plan = SubscriptionModel.fromJson(
        row({'kind': 'installment', 'installments_total': 12}),
      );
      expect(plan.isSingleCharge, isFalse);
    });

    test('says "Contado", never "MSI 1 de 1"', () {
      expect(cash().progressLabel, 'Contado');
      expect(
        SubscriptionModel.fromJson(
          row({
            'kind': 'installment',
            'installments_total': 12,
            'installments_paid': 3,
          }),
        ).progressLabel,
        'MSI 3 de 12',
      );
      expect(SubscriptionModel.fromJson(row({})).progressLabel, 'Mensual');
    });

    test('has its own chip, so the free-text field stays shut', () {
      expect(InstallmentTermSelectorWidget.isPreset(1), isTrue);
      expect(InstallmentTermSelectorWidget.isPreset(12), isTrue);
      expect(InstallmentTermSelectorWidget.isPreset(13), isFalse);
    });

    test('the preview does not say "1 pagos al mes"', () {
      String? preview(int count) => CommitmentSummary.preview(
        amount: 500,
        cycle: BillingCycle.monthly,
        customDays: '',
        firstCharge: DateTime(2026, 8, 14),
        isInstallment: true,
        installmentCount: count,
      );
      expect(preview(1), contains('pago único'));
      expect(preview(1), isNot(contains('al mes')));
      expect(preview(12), contains('12 pagos'));
    });
  });

  group('SubscriptionTileWidget', () {
    Widget host(SubscriptionModel item, {bool dark = false}) => MaterialApp(
      theme: dark ? AppTheme.dark : AppTheme.light,
      home: Scaffold(
        body: SubscriptionTileWidget(
          subscription: item,
          today: DateTime(2026, 9, 10),
          onTap: () {},
        ),
      ),
    );

    Color? barColour(WidgetTester tester) {
      final Iterable<Container> bars = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) => c.color != null);
      return bars.isEmpty ? null : bars.first.color;
    }

    testWidgets('the bar carries the card swatch, not the brand', (
      tester,
    ) async {
      await tester.pumpWidget(host(SubscriptionModel.fromJson(row({}))));
      // The row is on a Mastercard, whose brand red is #EB001B. The bar has to
      // be the colour the user picked for that card instead.
      expect(barColour(tester), AppColors.cardSwatches['morado']);
    });

    testWidgets('a paused row drops its colour and its urgency', (
      tester,
    ) async {
      final SubscriptionModel paused = SubscriptionModel.fromJson(
        row({'status': 'paused'}),
      );
      await tester.pumpWidget(host(paused));
      expect(barColour(tester), isNot(AppColors.cardSwatches['morado']));
      expect(find.text('En pausa'), findsOneWidget);
      // "en 5 días" on a stopped charge would be a lie.
      expect(find.textContaining('días'), findsNothing);
    });

    testWidgets('an archived card raises a warning on the row', (tester) async {
      await tester.pumpWidget(
        host(SubscriptionModel.fromJson(row({'card_archived': true}))),
      );
      expect(find.byType(WarningDotWidget), findsOneWidget);
    });

    testWidgets('a live card raises nothing', (tester) async {
      await tester.pumpWidget(host(SubscriptionModel.fromJson(row({}))));
      expect(find.byType(WarningDotWidget), findsNothing);
    });

    testWidgets('the meta line is never tinted with a brand colour', (
      tester,
    ) async {
      // Visa navy and Mastercard red both measured under 2:1 on the dark
      // paper. The card's identity is the bar's job.
      await tester.pumpWidget(
        host(SubscriptionModel.fromJson(row({})), dark: true),
      );
      final Text meta = tester.widget<Text>(
        find.textContaining('Mensual · NU'),
      );
      expect(meta.style?.color, anyOf(isNull, AppColors.mutedDark));
    });
  });
}
