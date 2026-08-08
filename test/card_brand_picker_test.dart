import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unit_of_payments/config/theme/app_spacing.dart';
import 'package:unit_of_payments/data/models/cards/card_model.dart';
import 'package:unit_of_payments/ui/widgets/cards/card_brand_picker_widget.dart';

void main() {
  /// Mirrors the bottom sheet the picker actually lives in: the same screen
  /// padding, so the row is measured against the width it really gets.
  Future<void> pumpPicker(WidgetTester tester, CardBrand selected) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: CardBrandPickerWidget(
                selected: selected,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      );

  Size tileSize(WidgetTester tester, CardBrand brand) => tester.getSize(
    find
        .ancestor(of: find.text(brand.label), matching: find.byType(Container))
        .first,
  );

  testWidgets('selecting a tile does not resize it', (tester) async {
    await pumpPicker(tester, CardBrand.visa);
    final Size selected = tileSize(tester, CardBrand.visa);
    final Size unselected = tileSize(tester, CardBrand.mastercard);

    // The ring is always drawn and only ever tinted. If it were added on
    // selection it would eat the padding and shove the whole row sideways.
    expect(selected, unselected);
  });

  testWidgets('every brand fits one row on a 375pt phone', (tester) async {
    tester.view.physicalSize = const Size(375, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpPicker(tester, CardBrand.visa);

    final double top = tester.getTopLeft(find.text(CardBrand.visa.label)).dy;
    for (final CardBrand brand in CardBrand.values) {
      expect(
        tester.getTopLeft(find.text(brand.label)).dy,
        top,
        reason: '${brand.label} wrapped to a second row',
      );
    }
  });
}
