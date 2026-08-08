import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unit_of_payments/config/theme/app_colors.dart';
import 'package:unit_of_payments/config/theme/app_theme.dart';
import 'package:unit_of_payments/data/models/subscriptions/subscription_model.dart';
import 'package:unit_of_payments/ui/widgets/subscriptions/subscription_kind_selector_widget.dart';

void main() {
  double contrast(Color a, Color b) {
    double channel(double value) => value <= 0.03928
        ? value / 12.92
        : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
    double luminance(Color c) =>
        0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
    final double x = luminance(a);
    final double y = luminance(b);
    return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
  }

  Color? fill(ThemeData theme, {required bool selected}) => theme
      .segmentedButtonTheme
      .style
      ?.backgroundColor
      ?.resolve(selected ? {WidgetState.selected} : <WidgetState>{});

  Color? label(ThemeData theme, {required bool selected}) => theme
      .segmentedButtonTheme
      .style
      ?.foregroundColor
      ?.resolve(selected ? {WidgetState.selected} : <WidgetState>{});

  for (final (
        String name,
        ThemeData theme,
        Color accent,
        Color ink,
        Color paper,
      )
      in [
        (
          'light',
          AppTheme.light,
          AppColors.accent,
          AppColors.ink,
          AppColors.paper,
        ),
        (
          'dark',
          AppTheme.dark,
          AppColors.accentDark,
          AppColors.inkDark,
          AppColors.paperDark,
        ),
      ]) {
    group('segmented button · $name', () {
      test('never fills a segment with the raw accent', () {
        // The Material default resolves secondaryContainer to secondary, which
        // paints the whole selected half in the accent — a block fill the
        // accent budget forbids outright.
        expect(fill(theme, selected: true), isNot(accent));
        expect(fill(theme, selected: false), Colors.transparent);
      });

      test('carries selection with ink, not colour alone', () {
        expect(label(theme, selected: true), ink);
        expect(label(theme, selected: false), isNot(ink));
      });

      test('the unselected label still clears 4.5:1', () {
        // neutral would look right and measure 3.61 in light mode. It is for
        // borders and text at 24px and up, never a 13px segment label.
        expect(
          contrast(label(theme, selected: false)!, paper),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('the theme asks for a 48px tap target', () {
        expect(
          theme.segmentedButtonTheme.style?.minimumSize
              ?.resolve(<WidgetState>{})
              ?.height,
          48,
        );
      });

      // The theme asking is not the same as the widget getting: a local
      // visualDensity + shrinkWrap once collapsed this to a measured 32 while
      // the token assertion above stayed green.
      testWidgets('and the rendered segment actually gets it', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Center(
                child: SubscriptionKindSelectorWidget(
                  value: ChargeKind.subscription,
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        );
        expect(
          tester.getSize(find.byType(SegmentedButton<ChargeKind>)).height,
          greaterThanOrEqualTo(48),
        );
      });
    });
  }
}
