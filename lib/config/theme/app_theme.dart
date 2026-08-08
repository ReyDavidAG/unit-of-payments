import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_motion.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Assembles both modes from the tokens. Nothing here invents a value.
class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(
    brightness: Brightness.light,
    paper: AppColors.paper,
    surface: AppColors.surface,
    surface2: AppColors.surface2,
    rule: AppColors.rule,
    neutral: AppColors.neutral,
    muted: AppColors.muted,
    ink: AppColors.ink,
    accent: AppColors.accent,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    focus: AppColors.focus,
    danger: AppColors.danger,
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    paper: AppColors.paperDark,
    surface: AppColors.surfaceDark,
    surface2: AppColors.surface2Dark,
    rule: AppColors.ruleDark,
    neutral: AppColors.neutralDark,
    muted: AppColors.mutedDark,
    ink: AppColors.inkDark,
    accent: AppColors.accentDark,
    primary: AppColors.primaryDark,
    onPrimary: AppColors.onPrimaryDark,
    focus: AppColors.focusDark,
    danger: AppColors.dangerDark,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color paper,
    required Color surface,
    required Color surface2,
    required Color rule,
    required Color neutral,
    required Color muted,
    required Color ink,
    required Color accent,
    required Color primary,
    required Color onPrimary,
    required Color focus,
    required Color danger,
  }) {
    final TextTheme text = AppTypography.textTheme(ink, muted);
    final BorderRadius inputRadius = BorderRadius.circular(
      AppSpacing.radiusInput,
    );
    final BorderRadius buttonRadius = BorderRadius.circular(
      AppSpacing.radiusCard,
    );

    return ThemeData(
      brightness: brightness,
      fontFamily: AppTypography.sans,
      scaffoldBackgroundColor: paper,
      textTheme: text,
      focusColor: focus,
      colorScheme: ColorScheme(
        brightness: brightness,
        // Primary is the chromatic button fill (deep teal) — distinct
        // from ink/paper and from coral. Buttons read as decided and
        // coloured, not as a black-and-white ink fill.
        primary: primary,
        onPrimary: onPrimary,
        secondary: accent,
        onSecondary: paper,
        error: danger,
        onError: paper,
        surface: paper,
        onSurface: ink,
        surfaceContainerLow: surface,
        surfaceContainerHigh: surface2,
        outline: neutral,
        outlineVariant: rule,
      ),
      dividerTheme: DividerThemeData(color: rule, space: 1, thickness: 1),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: surface2,
          disabledForegroundColor: neutral,
          textStyle: text.labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          // radiusCard (12) — not a pill. Matches cards and bottom sheets.
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          disabledForegroundColor: neutral,
          textStyle: text.labelLarge,
          side: BorderSide(color: primary),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: text.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: buttonRadius),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: text.bodyLarge?.copyWith(color: neutral),
        labelStyle: text.labelLarge?.copyWith(color: muted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: BorderSide(color: neutral),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: BorderSide(color: neutral),
        ),
        // Never animated in: a focus ring has to be there the instant focus is.
        // Focus uses primary (teal), not the coral accent — the focus
        // identity belongs to the same chromatic family as buttons.
        focusedBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: BorderSide(color: danger),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primary.withValues(alpha: 0.15),
        secondarySelectedColor: primary.withValues(alpha: 0.15),
        side: BorderSide(color: rule),
        labelStyle: text.labelLarge ?? const TextStyle(),
        secondaryLabelStyle: (text.labelLarge ?? const TextStyle()).copyWith(
          color: primary,
        ),
        shape: RoundedRectangleBorder(borderRadius: inputRadius),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: primary.withValues(alpha: 0.18),
        // Selected icon and label both read primary so the active tab
        // sits in the same chromatic identity as buttons and inputs.
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primary, size: 24);
          }
          return IconThemeData(color: muted, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = text.labelSmall ?? const TextStyle();
          if (states.contains(WidgetState.selected)) {
            return base.copyWith(color: primary, fontWeight: FontWeight.w500);
          }
          return base.copyWith(color: muted);
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: text.bodyLarge?.copyWith(color: paper),
        actionTextColor: accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusCard),
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: surface2,
        circularTrackColor: surface2,
      ),
      splashColor: surface2,
      highlightColor: surface2,
      listTileTheme: ListTileThemeData(
        titleTextStyle: text.bodyLarge,
        subtitleTextStyle: text.bodySmall,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: AppMotion.short,
        decoration: BoxDecoration(
          color: ink,
          borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
        ),
        textStyle: text.bodySmall?.copyWith(color: paper),
      ),
    );
  }
}
