import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../core/helpers/money_helper.dart';
import '../../../data/models/cards/card_model.dart';
import '../../../data/models/subscriptions/subscription_model.dart';

/// Create or edit a subscription. Returns the built model, or null when
/// dismissed. Persisting is the caller's job.
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
  late BillingCycle _cycle;
  late DateTime _firstCharge;
  late String? _cardId;
  late int _reminder;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final SubscriptionModel? item = widget.initial;
    _name = TextEditingController(text: item?.name ?? '');
    _amount = TextEditingController(
      text: item == null ? '' : item.amount.toStringAsFixed(2),
    );
    _customDays = TextEditingController(
      text: item?.customDays?.toString() ?? '',
    );
    _cycle = item?.cycle ?? BillingCycle.monthly;
    _firstCharge = item?.firstChargeDate ?? DateTime.now();
    _cardId = item?.cardId;
    _reminder = item?.reminderDaysBefore ?? 1;
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _customDays.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
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
    Navigator.of(context).pop(
      SubscriptionModel(
        id: widget.initial?.id ?? '',
        name: _name.text.trim(),
        amount: double.parse(_amount.text.replaceAll(',', '.')),
        cycle: _cycle,
        customDays: int.tryParse(_customDays.text),
        firstChargeDate: _firstCharge,
        cardId: _cardId,
        reminderDaysBefore: _reminder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEdit ? 'Editar suscripción' : 'Nueva suscripción',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _name,
                autofocus: !_isEdit,
                textCapitalization: TextCapitalization.words,
                maxLength: 60,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Netflix',
                ),
                validator: (value) =>
                    (value?.trim().isEmpty ?? true) ? 'Ponle un nombre.' : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixText: r'$ ',
                ),
                validator: _validateAmount,
              ),
              const SizedBox(height: AppSpacing.md),
              _CycleSelector(
                value: _cycle,
                onChanged: (cycle) => setState(() => _cycle = cycle),
              ),
              if (_cycle == BillingCycle.custom) ...[
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _customDays,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Cada X días'),
                  validator: _validateCustomDays,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Primer cobro'),
                subtitle: Text(MoneyHelper.longDate(_firstCharge)),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _pickDate,
              ),
              const SizedBox(height: AppSpacing.xs),
              _CardSelector(
                cards: widget.cards,
                value: _cardId,
                onChanged: (id) => setState(() => _cardId = id),
              ),
              const SizedBox(height: AppSpacing.md),
              _ReminderSelector(
                value: _reminder,
                onChanged: (days) => setState(() => _reminder = days),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(_isEdit ? 'Guardar' : 'Agregar suscripción'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateAmount(String? value) {
    final double? amount = double.tryParse((value ?? '').replaceAll(',', '.'));
    if (amount == null) {
      return 'Escribe un monto.';
    }
    // Mirrors the subs_amount_pos constraint, so the error arrives before
    // the round trip instead of after it.
    return amount > 0 ? null : 'Debe ser mayor que cero.';
  }

  String? _validateCustomDays(String? value) {
    final int? days = int.tryParse(value ?? '');
    return (days != null && days >= 1 && days <= 365)
        ? null
        : 'Entre 1 y 365 días.';
  }
}

class _CycleSelector extends StatelessWidget {
  const _CycleSelector({required this.value, required this.onChanged});

  final BillingCycle value;
  final ValueChanged<BillingCycle> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      children: [
        for (final BillingCycle cycle in BillingCycle.values)
          ChoiceChip(
            label: Text(cycle.label),
            selected: cycle == value,
            onSelected: (_) => onChanged(cycle),
          ),
      ],
    );
  }
}

class _CardSelector extends StatelessWidget {
  const _CardSelector({
    required this.cards,
    required this.value,
    required this.onChanged,
  });

  final List<CardModel> cards;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      initialValue: value,
      decoration: const InputDecoration(labelText: 'Tarjeta'),
      items: [
        const DropdownMenuItem<String?>(child: Text('Sin tarjeta')),
        for (final CardModel card in cards)
          DropdownMenuItem<String?>(value: card.id, child: Text(card.alias)),
      ],
      onChanged: onChanged,
    );
  }
}

class _ReminderSelector extends StatelessWidget {
  const _ReminderSelector({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  static const Map<int, String> _options = {
    0: 'El mismo día',
    1: '1 día antes',
    3: '3 días antes',
    7: '7 días antes',
  };

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: _options.containsKey(value) ? value : 1,
      decoration: const InputDecoration(labelText: 'Avisarme'),
      items: [
        for (final MapEntry<int, String> option in _options.entries)
          DropdownMenuItem<int>(value: option.key, child: Text(option.value)),
      ],
      onChanged: (days) => onChanged(days ?? 1),
    );
  }
}
