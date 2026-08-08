import 'package:flutter/material.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/letter_palette.dart';

/// Big avatar in the profile screen. A circle with the first letter of the
/// user's email, bordered in the colour the letter pulls from [letterPalette].
/// The fill is `surface` so the letter and border read against the paper,
/// not against a filled tile that competes with the page.
class IdentityHeader extends StatelessWidget {
  const IdentityHeader({required this.email, super.key});

  final String email;

  static const double _avatarSize = 112;
  static const double _borderWidth = 3;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String letter = email.isEmpty
        ? '?'
        : email.substring(0, 1).toUpperCase();
    final Color borderColor = letterPaletteColor(letter);

    return Column(
      children: [
        Container(
          width: _avatarSize,
          height: _avatarSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.surface,
            border: Border.all(color: borderColor, width: _borderWidth),
          ),
          child: Text(
            letter,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 48,
              fontWeight: FontWeight.w700,
              height: 1,
              color: borderColor,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'TU CUENTA',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: AppSpacing.xs2),
        Text(
          email.isEmpty ? 'Sin correo' : email,
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'A tiempo con cada cobro.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
