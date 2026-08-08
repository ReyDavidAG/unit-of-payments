import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/app_typography.dart';
import '../../../data/models/subscriptions/subscription_model.dart';

/// A money input. Accepts a comma or a dot as the decimal mark, because both
/// keyboards ship one and neither user is wrong.
///
/// `display` lifts the figure to the 40 dp mono protagonist role — the one
/// number the user is about to commit to. A subtle outline + floating label
/// keep it reading as an input, not as a label that happens to be tappable.
class AmountFieldWidget extends StatelessWidget {
  const AmountFieldWidget({
    required this.controller,
    required this.label,
    this.display = false,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final bool display;

  /// Mirrors subs_amount_pos, so the error arrives before the round trip.
  static String? validate(String? value) {
    final double? amount = double.tryParse((value ?? '').replaceAll(',', '.'));
    if (amount == null) {
      return 'Escribe un monto.';
    }
    return amount > 0 ? null : 'Debe ser mayor que cero.';
  }

  /// The one place that reads a typed figure back as a number.
  static double? parse(String value) =>
      double.tryParse(value.replaceAll(',', '.'));

  /// The stored amount is the monthly charge, but the user thinks in the price
  /// they paid, so an existing plan is read back out to its total.
  static String initialText(SubscriptionModel? item) {
    if (item == null) {
      return '';
    }
    final int? count = item.installmentsTotal;
    return item.isInstallment && count != null
        ? (item.amount * count).toStringAsFixed(2)
        : item.amount.toStringAsFixed(2);
  }

  OutlineInputBorder _border(Color color, {required bool focused}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
        borderSide: BorderSide(color: color, width: focused ? 2 : 1),
      );

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color ink = theme.colorScheme.onSurface;
    final TextStyle figure = AppTypography.displayAmount(ink);
    if (display) {
      return TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        style: figure,
        textAlign: TextAlign.start,
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          hintText: '0.00',
          prefixText: r'$ ',
          prefixStyle: figure,
          floatingLabelStyle: TextStyle(
            fontFamily: 'Geist',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.primary,
          ),
          labelStyle: TextStyle(
            fontFamily: 'Geist',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          focusedBorder: _border(theme.colorScheme.primary, focused: true),
          enabledBorder: _border(
            theme.colorScheme.outlineVariant,
            focused: false,
          ),
        ),
        validator: validate,
      );
    }
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(labelText: label, prefixText: r'$ '),
      validator: validate,
    );
  }
}
