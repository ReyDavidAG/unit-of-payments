import 'package:flutter/material.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../data/models/subscriptions/subscription_model.dart';
import '../../widgets/subscriptions/amount_field_widget.dart';
import '../../widgets/subscriptions/billing_cycle_selector_widget.dart';
import '../../widgets/subscriptions/installment_term_selector_widget.dart';
import '../../widgets/subscriptions/name_field_widget.dart';
import '../../widgets/subscriptions/subscription_kind_selector_widget.dart';

/// What is being paid and in what shape: kind, name, amount, then either a
/// term or a billing cycle. The two are mutually exclusive by construction —
/// an installment plan is always monthly, so it never asks for a cycle.
class FormChargeSection extends StatelessWidget {
  const FormChargeSection({
    required this.kind,
    required this.onKind,
    required this.name,
    required this.amount,
    required this.autofocusName,
    required this.term,
    required this.isCustomTerm,
    required this.onTerm,
    required this.installments,
    required this.breakdown,
    required this.cycle,
    required this.onCycle,
    required this.customDays,
    super.key,
  });

  final ChargeKind kind;
  final ValueChanged<ChargeKind> onKind;
  final TextEditingController name;
  final TextEditingController amount;
  final bool autofocusName;

  final int? term;
  final bool isCustomTerm;
  final ValueChanged<int?> onTerm;
  final TextEditingController installments;
  final String? breakdown;

  final BillingCycle cycle;
  final ValueChanged<BillingCycle> onCycle;
  final TextEditingController customDays;

  bool get _isInstallment => kind == ChargeKind.installment;

  @override
  Widget build(BuildContext context) {
    final int? count = isCustomTerm ? int.tryParse(installments.text) : term;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SubscriptionKindSelectorWidget(value: kind, onChanged: onKind),
        const SizedBox(height: AppSpacing.sectionGap),
        NameFieldWidget(
          controller: name,
          isInstallment: _isInstallment,
          autofocus: autofocusName,
        ),
        const SizedBox(height: AppSpacing.lg),
        AmountFieldWidget(
          controller: amount,
          // On contado the total *is* the charge, so "Monto total" would imply
          // a split that never happens.
          label:
              _isInstallment && count != InstallmentTermSelectorWidget.contado
              ? 'Monto total'
              : 'Monto',
          display: true,
        ),
        const SizedBox(height: AppSpacing.md),
        if (_isInstallment)
          InstallmentTermSelectorWidget(
            term: term,
            isCustom: isCustomTerm,
            onTerm: onTerm,
            controller: installments,
            breakdown: breakdown,
          )
        else
          BillingCycleSelectorWidget(
            value: cycle,
            onChanged: onCycle,
            controller: customDays,
          ),
      ],
    );
  }
}
