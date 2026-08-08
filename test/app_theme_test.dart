import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unit_of_payments/config/theme/app_colors.dart';
import 'package:unit_of_payments/config/theme/app_typography.dart';
import 'package:unit_of_payments/main.dart';

void main() {
  testWidgets('theme resolves to the locked tokens', (tester) async {
    await tester.pumpWidget(const MainApp());
    final ThemeData theme = Theme.of(
      tester.element(find.byType(Scaffold).first),
    );

    expect(theme.scaffoldBackgroundColor, AppColors.paper);
    expect(theme.textTheme.bodyLarge?.fontFamily, AppTypography.sans);

    // Primary is ink, not accent: an accent-filled button fails contrast.
    expect(theme.colorScheme.primary, AppColors.ink);
    expect(theme.colorScheme.secondary, AppColors.accent);
  });

  test('amounts use tabular figures so columns of money align', () {
    expect(
      AppTypography.amount(AppColors.ink).fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  test('card swatches fall back instead of throwing', () {
    expect(AppColors.swatchFromHex('#4B84E2'), AppColors.defaultSwatch);
    expect(AppColors.swatchFromHex('#C46D01'), AppColors.cardSwatches['amber']);
    // An off-palette or malformed value must not crash a list.
    expect(AppColors.swatchFromHex('#4A5568'), AppColors.defaultSwatch);
    expect(AppColors.swatchFromHex('nope'), AppColors.defaultSwatch);
    expect(AppColors.swatchFromHex(null), AppColors.defaultSwatch);
  });
}
