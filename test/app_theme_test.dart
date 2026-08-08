import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unit_of_payments/config/theme/app_colors.dart';
import 'package:unit_of_payments/config/theme/app_theme.dart';
import 'package:unit_of_payments/config/theme/app_typography.dart';

void main() {
  testWidgets('theme resolves to the locked tokens', (tester) async {
    // Pumps the theme directly: MainApp now needs a live Supabase client.
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const Scaffold()),
    );
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
    expect(AppColors.swatchFromHex('#494ECF'), AppColors.defaultSwatch);
    expect(AppColors.swatchFromHex('#D57700'), AppColors.cardSwatches['amber']);
    // An off-palette or malformed value must not crash a list.
    // A colour from the retired eight-swatch set must not render as itself.
    expect(AppColors.swatchFromHex('#C46D01'), AppColors.defaultSwatch);
    expect(AppColors.swatchFromHex('nope'), AppColors.defaultSwatch);
    expect(AppColors.swatchFromHex(null), AppColors.defaultSwatch);
  });
}
