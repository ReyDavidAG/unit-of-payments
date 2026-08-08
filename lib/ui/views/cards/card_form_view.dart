import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../core/helpers/card_brand_helper.dart';
import '../../../data/models/cards/card_model.dart';
import '../../widgets/cards/card_brand_picker_widget.dart';
import '../../widgets/cards/card_swatch_picker_widget.dart';

/// Create or edit a card alias, in a bottom sheet. Returns the built model,
/// or null when dismissed. Persisting is the caller's job.
class CardFormView extends StatefulWidget {
  const CardFormView({this.initial, super.key});

  final CardModel? initial;

  static Future<CardModel?> show(BuildContext context, {CardModel? initial}) =>
      showModalBottomSheet<CardModel>(
        context: context,
        isScrollControlled: true,
        builder: (_) => CardFormView(initial: initial),
      );

  @override
  State<CardFormView> createState() => _CardFormViewState();
}

class _CardFormViewState extends State<CardFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _alias;
  late final TextEditingController _last4;
  late final TextEditingController _cutoff;
  late final TextEditingController _due;
  late CardBrand _brand;
  // Kept so the DB column is still populated, but no UI surfaces it.
  late String _color;

  /// The brand follows the alias until the user overrides it by tapping a
  /// tile, or until an existing card arrives with a brand worth keeping.
  late bool _brandLocked;
  bool _brandSuggested = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final CardModel? card = widget.initial;
    _alias = TextEditingController(text: card?.alias ?? '');
    _last4 = TextEditingController(text: card?.last4 ?? '');
    _cutoff = TextEditingController(text: card?.cutoffDay?.toString() ?? '');
    _due = TextEditingController(text: card?.paymentDueDay?.toString() ?? '');
    _brand = card?.brand ?? CardBrand.other;
    _color = card?.color ?? AppColors.hexOf(AppColors.defaultSwatch);
    _brandLocked = card != null && card.brand != CardBrand.other;
    _alias.addListener(_suggestBrand);
  }

  /// Re-runs on every keystroke, so deleting the name that triggered a guess
  /// takes the guess with it.
  void _suggestBrand() {
    if (_brandLocked) {
      return;
    }
    final CardBrand next =
        CardBrandHelper.detect(_alias.text) ?? CardBrand.other;
    if (next == _brand) {
      return;
    }
    setState(() {
      _brand = next;
      _brandSuggested = next != CardBrand.other;
    });
  }

  void _selectBrand(CardBrand brand) => setState(() {
    _brand = brand;
    _brandLocked = true;
    _brandSuggested = false;
  });

  @override
  void dispose() {
    _alias.dispose();
    _last4.dispose();
    _cutoff.dispose();
    _due.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final CardModel card = CardModel(
      id: widget.initial?.id ?? '',
      alias: _alias.text.trim(),
      brand: _brand,
      color: _color,
      last4: _last4.text.isEmpty ? null : _last4.text,
      cutoffDay: int.tryParse(_cutoff.text),
      paymentDueDay: int.tryParse(_due.text),
    );
    Navigator.of(context).pop(card);
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
                _isEdit ? 'Editar tarjeta' : 'Nueva tarjeta',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _alias,
                autofocus: !_isEdit,
                textCapitalization: TextCapitalization.words,
                maxLength: 40,
                decoration: const InputDecoration(
                  labelText: 'Alias',
                  hintText: 'BBVA Oro',
                ),
                validator: (value) =>
                    (value?.trim().isEmpty ?? true) ? 'Ponle un nombre.' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Marca', style: theme.textTheme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              CardBrandPickerWidget(selected: _brand, onSelected: _selectBrand),
              if (_brandSuggested) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'La detectamos por el nombre. Tócala para cambiarla.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text('Color', style: theme.textTheme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              CardSwatchPickerWidget(
                selected: _color,
                onSelected: (color) => setState(() => _color = color),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _last4,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      // Four digits and nothing more: this field must never be
                      // able to hold a full card number.
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Últimos 4',
                        helperText: 'Opcional',
                      ),
                      validator: (value) =>
                          (value == null || value.isEmpty || value.length == 4)
                          ? null
                          : 'Deben ser 4 dígitos.',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(child: SizedBox()),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              // The two dates sit together because they are read together and
              // are the pair users mix up.
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cutoff,
                      keyboardType: TextInputType.number,
                      maxLength: 2,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Día de corte',
                        counterText: '',
                      ),
                      validator: _validateDay,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _due,
                      keyboardType: TextInputType.number,
                      maxLength: 2,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Día límite',
                        counterText: '',
                      ),
                      validator: _validateDay,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'El corte cierra tu estado de cuenta. El límite es el día en '
                'que hay que pagarlo, y el que te avisamos.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(_isEdit ? 'Guardar' : 'Agregar tarjeta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateDay(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final int? day = int.tryParse(value);
    return (day != null && day >= 1 && day <= 31) ? null : 'Entre 1 y 31.';
  }
}
