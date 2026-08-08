import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../data/models/cards/card_model.dart';
import '../../widgets/cards/card_brand_picker_widget.dart';

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
  late CardBrand _brand;
  // Kept so the DB column is still populated, but no UI surfaces it.
  late String _color;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final CardModel? card = widget.initial;
    _alias = TextEditingController(text: card?.alias ?? '');
    _last4 = TextEditingController(text: card?.last4 ?? '');
    _cutoff = TextEditingController(text: card?.cutoffDay?.toString() ?? '');
    _brand = card?.brand ?? CardBrand.other;
    _color = card?.color ?? AppColors.hexOf(AppColors.defaultSwatch);
  }

  @override
  void dispose() {
    _alias.dispose();
    _last4.dispose();
    _cutoff.dispose();
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
              CardBrandPickerWidget(
                selected: _brand,
                onSelected: (brand) => setState(() => _brand = brand),
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
                  Expanded(
                    child: TextFormField(
                      controller: _cutoff,
                      keyboardType: TextInputType.number,
                      maxLength: 2,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Día de corte',
                        helperText: 'Opcional',
                      ),
                      validator: _validateCutoff,
                    ),
                  ),
                ],
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

  String? _validateCutoff(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final int? day = int.tryParse(value);
    return (day != null && day >= 1 && day <= 31) ? null : 'Entre 1 y 31.';
  }
}
