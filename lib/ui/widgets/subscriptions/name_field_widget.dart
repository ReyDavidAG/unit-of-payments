import 'package:flutter/material.dart';

/// What the charge is called. The hint changes with the kind because the two
/// answers look nothing alike: a service has a brand, a plan has an object.
class NameFieldWidget extends StatelessWidget {
  const NameFieldWidget({
    required this.controller,
    required this.isInstallment,
    required this.autofocus,
    super.key,
  });

  final TextEditingController controller;
  final bool isInstallment;
  final bool autofocus;

  /// Mirrors subs_name_len, so the error arrives before the round trip.
  static String? validate(String? value) =>
      (value?.trim().isEmpty ?? true) ? 'Ponle un nombre.' : null;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    autofocus: autofocus,
    textCapitalization: TextCapitalization.words,
    maxLength: 60,
    decoration: InputDecoration(
      labelText: 'Nombre',
      hintText: isInstallment ? 'Refrigerador' : 'Netflix',
    ),
    validator: validate,
  );
}
