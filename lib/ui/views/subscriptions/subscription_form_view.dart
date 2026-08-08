import 'package:flutter/material.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../core/helpers/commitment_summary.dart';
import '../../../core/helpers/money_helper.dart';
import '../../../data/models/cards/card_model.dart';
import '../../../data/models/subscriptions/subscription_model.dart';
import '../../widgets/subscriptions/amount_field_widget.dart';
import '../../widgets/subscriptions/billing_cycle_selector_widget.dart';
import '../../widgets/subscriptions/card_selector_widget.dart';
import '../../widgets/subscriptions/first_charge_row_widget.dart';
import '../../widgets/common/custom_date_picker.dart';
import '../../widgets/subscriptions/installment_term_selector_widget.dart';
import '../../widgets/subscriptions/subscription_kind_selector_widget.dart';
import 'form_header.dart';
import 'form_optional_section.dart';

/// Create or edit a subscription or an installment plan. Returns the built
/// model, or null when dismissed. Persisting is the caller's job.
class SubscriptionFormView extends StatefulWidget {
  const SubscriptionFormView({required this.cards, this.initial, super.key});

  final List<CardModel> cards;
  final SubscriptionModel? initial;

  static Future<SubscriptionModel?> show(
    BuildContext context, {
    required List<CardModel> cards,
    SubscriptionModel? initial,
  }) => showModalBottomSheet<SubscriptionModel>(
    context: context,
    isScrollControlled: true,
    // iOS notch / status bar would otherwise sit on top of the sheet.
    useSafeArea: true,
    // Cap at 90% so the parent route stays visible behind it.
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.9,
    ),
    // `showDragHandle: true` swallows drag-to-dismiss combined with the inner
    // SingleChildScrollView; the handle is drawn inline instead.
    builder: (_) => SubscriptionFormView(cards: cards, initial: initial),
  );

  @override
  State<SubscriptionFormView> createState() => _SubscriptionFormViewState();
}

class _SubscriptionFormViewState extends State<SubscriptionFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late final TextEditingController _customDays;
  late final TextEditingController _installments;
  late final TextEditingController _owedBy;
  late ChargeKind _kind;
  late BillingCycle _cycle;

  /// Null while "Otro" is active; the count then lives in [_installments].
  int? _term;
  bool _customTerm = false;
  late DateTime _firstCharge;
  late String? _cardId;
  late int _reminder;

  bool get _isEdit => widget.initial != null;
  bool get _isInstallment => _kind == ChargeKind.installment;

  /// Far and away the most common promotion, so it costs the user no taps.
  static const int _defaultTerm = 12;

  int? get _installmentCount =>
      _customTerm ? int.tryParse(_installments.text) : _term;

  static String _initialAmount(SubscriptionModel? item) {
    if (item == null) {
      return '';
    }
    final int? count = item.installmentsTotal;
    return item.kind == ChargeKind.installment && count != null
        ? (item.amount * count).toStringAsFixed(2)
        : item.amount.toStringAsFixed(2);
  }

  @override
  void initState() {
    super.initState();
    final SubscriptionModel? item = widget.initial;
    _name = TextEditingController(text: item?.name ?? '');
    _amount = TextEditingController(text: _initialAmount(item));
    _customDays = TextEditingController(
      text: item?.customDays?.toString() ?? '',
    );
    // The stored amount is the monthly charge, but the user thinks in the price
    // they paid, so an existing plan is read back out to its total.
    final int? count = item?.installmentsTotal;
    _customTerm =
        count != null && !InstallmentTermSelectorWidget.terms.contains(count);
    _term = _customTerm ? null : (count ?? _defaultTerm);
    _installments = TextEditingController(
      text: _customTerm ? count.toString() : '',
    );
    _owedBy = TextEditingController(text: item?.owedBy ?? '');
    _kind = item?.kind ?? ChargeKind.subscription;
    _cycle = item?.cycle ?? BillingCycle.monthly;
    _firstCharge = item?.firstChargeDate ?? DateTime.now();
    _cardId = item?.cardId;
    _reminder = item?.reminderDaysBefore ?? 1;
    // Live preview and installment breakdown both derive from these, so any
    // change must rebuild.
    _amount.addListener(_refresh);
    _installments.addListener(_refresh);
    _customDays.addListener(_refresh);
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _customDays.dispose();
    _installments.dispose();
    _owedBy.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  /// The database only accepts a monthly installment plan, so switching kind
  /// forces the cycle rather than letting the write fail on the constraint.
  void _selectKind(ChargeKind kind) => setState(() {
    _kind = kind;
    if (kind == ChargeKind.installment) {
      _cycle = BillingCycle.monthly;
      _term ??= _defaultTerm;
    }
  });

  void _selectTerm(int? months) => setState(() {
    _customTerm = months == null;
    _term = months;
  });

  Future<void> _pickDate() async {
    final DateTime? picked = await CustomDatePicker.show(
      context,
      initialDate: _firstCharge,
      // Past dates are the norm: most subscriptions started before the app did.
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 10),
    );
    if (picked != null) {
      setState(() => _firstCharge = picked);
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final String owedBy = _owedBy.text.trim();
    final double typed = AmountFieldWidget.parse(_amount.text)!;
    final int? count = _installmentCount;
    if (_isInstallment && count == null) {
      return;
    }
    Navigator.of(context).pop(
      SubscriptionModel(
        id: widget.initial?.id ?? '',
        name: _name.text.trim(),
        // The field holds the price on a plan and the charge on everything
        // else; the column always holds the charge.
        amount: _isInstallment
            ? MoneyHelper.installmentAmount(typed, count!)
            : typed,
        cycle: _cycle,
        customDays: int.tryParse(_customDays.text),
        firstChargeDate: _firstCharge,
        cardId: _cardId,
        reminderDaysBefore: _reminder,
        kind: _kind,
        installmentsTotal: _isInstallment ? count : null,
        owedBy: owedBy.isEmpty ? null : owedBy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? breakdown = CommitmentSummary.breakdown(
      total: AmountFieldWidget.parse(_amount.text),
      count: _installmentCount,
    );
    final String? preview = CommitmentSummary.preview(
      amount: AmountFieldWidget.parse(_amount.text),
      cycle: _cycle,
      customDays: _customDays.text,
      firstCharge: _firstCharge,
      isInstallment: _isInstallment,
      installmentCount: _installmentCount,
    );

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        top: AppSpacing.xs,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FormHeader(
                isEdit: _isEdit,
                onClose: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: AppSpacing.md),
              SubscriptionKindSelectorWidget(
                value: _kind,
                onChanged: _selectKind,
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              TextFormField(
                controller: _name,
                autofocus: !_isEdit,
                textCapitalization: TextCapitalization.words,
                maxLength: 60,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  hintText: _isInstallment ? 'Refrigerador' : 'Netflix',
                ),
                validator: (value) =>
                    (value?.trim().isEmpty ?? true) ? 'Ponle un nombre.' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              AmountFieldWidget(
                controller: _amount,
                label: _isInstallment ? 'Monto total' : 'Monto',
                display: true,
              ),
              if (_isInstallment) ...[
                const SizedBox(height: AppSpacing.md),
                InstallmentTermSelectorWidget(
                  term: _term,
                  isCustom: _customTerm,
                  onTerm: _selectTerm,
                  controller: _installments,
                  breakdown: breakdown,
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.md),
                BillingCycleSelectorWidget(
                  value: _cycle,
                  onChanged: (cycle) => setState(() => _cycle = cycle),
                  controller: _customDays,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              FirstChargeRowWidget(
                isInstallment: _isInstallment,
                date: _firstCharge,
                daysUntil: _firstCharge.difference(DateTime.now()).inDays,
                onTap: _pickDate,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Tarjeta', style: theme.textTheme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              CardSelectorWidget(
                cards: widget.cards,
                value: _cardId,
                onChanged: (id) => setState(() => _cardId = id),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              FormOptionalSection(
                owedByController: _owedBy,
                reminderDays: _reminder,
                onReminderChanged: (days) => setState(() => _reminder = days),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (preview != null) ...[
                Text(preview, style: theme.textTheme.bodySmall),
                const SizedBox(height: AppSpacing.sm),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(_isEdit ? 'Guardar' : 'Agregar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
