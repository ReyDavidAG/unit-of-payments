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
      // Untheme this and Material fills the selected segment with
      // colorScheme.secondaryContainer, which defaults to secondary — the raw
      // accent, as a full-width block. Banned by the accent budget, and it made
      // segments and chips speak two different selection languages on one form.
      // They now say the same thing: a 15% primary wash, ink label, hairline
      // rule, radiusInput.
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? primary.withValues(alpha: 0.15)
                : Colors.transparent,
          ),
          // Ink against muted is the signal that survives a tinted fill; the
          // wash alone would be too quiet to carry selection on its own.
          // Muted, never neutral: an unselected segment is a 13px label and
          // neutral only clears contrast at 24px and up.
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? ink : muted,
          ),
          overlayColor: WidgetStateProperty.all(surface2),
          side: WidgetStateProperty.all(BorderSide(color: rule)),
          textStyle: WidgetStateProperty.all(text.labelLarge),
          // 48 high: a segment is a tap target before it is a label.
          minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: inputRadius),
          ),
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
