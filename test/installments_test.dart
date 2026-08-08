import 'package:flutter_test/flutter_test.dart';
import 'package:unit_of_payments/core/helpers/money_helper.dart';
import 'package:unit_of_payments/data/models/cards/card_model.dart';
import 'package:unit_of_payments/data/models/cards/card_statement_model.dart';
import 'package:unit_of_payments/data/models/subscriptions/debtor_model.dart';
import 'package:unit_of_payments/data/models/subscriptions/subscription_model.dart';

void main() {
  group('SubscriptionModel · installments', () {
    // Shaped like a real v_subscriptions row: Postgres sends numeric as a
    // string so JSON cannot round it.
    Map<String, dynamic> row(Map<String, dynamic> overrides) => {
      'id': 'sub-1',
      'name': 'Refrigerador',
      'amount': '1000.00',
      'cycle': 'monthly',
      'first_charge_date': '2026-03-15',
      'kind': 'installment',
      'installments_total': 12,
      'installments_paid': 5,
      'installments_left': 7,
      'outstanding': '7000.00',
      'owed_by': 'Juan',
      ...overrides,
    };

    test('reads the plan and its progress from the view', () {
      final SubscriptionModel item = SubscriptionModel.fromJson(row({}));

      expect(item.kind, ChargeKind.installment);
      expect(item.isInstallment, isTrue);
      expect(item.installmentsTotal, 12);
      expect(item.installmentsPaid, 5);
      expect(item.installmentsLeft, 7);
      expect(item.outstanding, 7000);
      expect(item.owedBy, 'Juan');
    });

    test('outstanding survives the string Postgres actually sends', () {
      // `as num` here would throw; a silent zero would understate the debt.
      expect(SubscriptionModel.fromJson(row({})).outstanding, 7000.0);
      expect(
        SubscriptionModel.fromJson(row({'outstanding': null})).outstanding,
        0,
      );
    });

    test('an unknown kind falls back instead of throwing', () {
      expect(
        SubscriptionModel.fromJson(row({'kind': 'something_new'})).kind,
        ChargeKind.subscription,
      );
    });

    test('a row with no installment fields is an open subscription', () {
      final SubscriptionModel item = SubscriptionModel.fromJson({
        'id': 'sub-2',
        'name': 'Netflix',
        'amount': '219.00',
        'cycle': 'monthly',
        'first_charge_date': '2026-01-05',
      });

      expect(item.kind, ChargeKind.subscription);
      expect(item.isInstallment, isFalse);
      expect(item.installmentsTotal, isNull);
      // Zero, not null, so summing debt across a list is a plain sum.
      expect(item.outstanding, 0);
    });

    test('toWrite drops the installment count on a subscription', () {
      final SubscriptionModel plan = SubscriptionModel(
        id: '',
        name: 'Refrigerador',
        amount: 1000,
        cycle: BillingCycle.monthly,
        firstChargeDate: _march15,
        kind: ChargeKind.installment,
        installmentsTotal: 12,
      );
      expect(plan.toWrite()['installments_total'], 12);
      expect(plan.toWrite()['kind'], 'installment');

      // Mirrors subs_installments: the constraint rejects a count on a
      // subscription, so the client must not send one either.
      final SubscriptionModel asSubscription = SubscriptionModel(
        id: '',
        name: 'Netflix',
        amount: 219,
        cycle: BillingCycle.monthly,
        firstChargeDate: _march15,
        installmentsTotal: 12,
      );
      expect(asSubscription.toWrite()['installments_total'], isNull);
      expect(asSubscription.toWrite()['kind'], 'subscription');
    });
  });

  group('CardStatementModel', () {
    CardStatementModel build({String? dueOn, String owed = '0'}) =>
        CardStatementModel.fromJson({
          'card_id': 'card-1',
          'alias': 'BBVA Oro',
          'color': '#494ECF',
          'opens_after': '2026-07-20',
          'closes_on': '2026-08-20',
          'due_on': dueOn,
          'total_due': '1240.00',
          'owed_by_others': owed,
          'yours': '1240.00',
          'line_count': 3,
        });

    test('reads the window and the money', () {
      final CardStatementModel statement = build(dueOn: '2026-09-10');
      expect(statement.opensAfter, DateTime(2026, 7, 20));
      expect(statement.closesOn, DateTime(2026, 8, 20));
      expect(statement.dueOn, DateTime(2026, 9, 10));
      expect(statement.totalDue, 1240);
      expect(statement.hasCharges, isTrue);
    });

    test('counts the days left to pay', () {
      final CardStatementModel statement = build(dueOn: '2026-09-10');
      expect(statement.daysUntilDue(DateTime(2026, 9, 10)), 0);
      expect(statement.daysUntilDue(DateTime(2026, 9, 8)), 2);
      expect(statement.daysUntilDue(DateTime(2026, 9, 12)), -2);
    });

    test('a card with no due day has a total but no deadline', () {
      final CardStatementModel statement = build();
      expect(statement.dueOn, isNull);
      expect(statement.daysUntilDue(DateTime(2026, 8, 8)), isNull);
    });

    test('shared only when someone actually repays part of it', () {
      expect(build(owed: '0').isShared, isFalse);
      expect(build(owed: '1000.00').isShared, isTrue);
    });
  });

  group('DebtorModel', () {
    test('reads a grouped row', () {
      final DebtorModel debtor = DebtorModel.fromJson({
        'owed_by': 'Juan',
        'plan_count': 2,
        'monthly_amount': '1500.00',
        'outstanding': '9000.00',
        'next_charge_date': '2026-09-15',
      });

      expect(debtor.name, 'Juan');
      expect(debtor.planCount, 2);
      expect(debtor.monthlyAmount, 1500);
      expect(debtor.outstanding, 9000);
      expect(debtor.hasEnd, isTrue);
    });

    test('an open-ended split has no end', () {
      final DebtorModel debtor = DebtorModel.fromJson({
        'owed_by': 'Ana',
        'plan_count': 1,
        'monthly_amount': '110.00',
        'outstanding': '0',
      });
      expect(debtor.hasEnd, isFalse);
    });
  });

  group('MoneyHelper.installmentAmount', () {
    test('splits a price into the charge the card actually sees', () {
      expect(MoneyHelper.installmentAmount(12000, 12), 1000);
      expect(MoneyHelper.installmentAmount(4500, 3), 1500);
    });

    test('rounds to cents, and the shortfall is real', () {
      // 10000/12 is 833.333...; the card is billed 833.33, so twelve of them
      // land four cents under the price. The form shows that rather than
      // pretending the division was exact.
      final double monthly = MoneyHelper.installmentAmount(10000, 12);
      expect(monthly, 833.33);
      expect(monthly * 12, closeTo(9999.96, 0.001));
    });

    test('round-trips once stored, so editing does not drift', () {
      // The form reads a stored plan back out as amount * count, then splits
      // it again on save. That has to be stable or a plan loses cents on
      // every edit.
      final double first = MoneyHelper.installmentAmount(10000, 12);
      final double again = MoneyHelper.installmentAmount(first * 12, 12);
      expect(again, first);
    });
  });

  test('CardModel carries the payment due day both ways', () {
    final CardModel card = CardModel.fromJson({
      'id': 'card-1',
      'alias': 'BBVA Oro',
      'brand': 'visa',
      'color': '#494ECF',
      'cutoff_day': 20,
      'payment_due_day': 10,
    });

    expect(card.cutoffDay, 20);
    expect(card.paymentDueDay, 10);
    expect(card.toInsert()['payment_due_day'], 10);
  });
}

final DateTime _march15 = DateTime(2026, 3, 15);
