import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_spacing.dart';
import '../../../config/theme/letter_palette.dart';
import '../../../data/services/supabase/supabase_service.dart';
import '../../screens/profile/profile_screen.dart';

/// AppBar entry-point to the profile screen. A small circle with the first
/// letter of the user's email, bordered in the colour the letter pulls from
/// [letterPalette]. Replaces the previous account_circle_outlined icon so
/// the user has a stable, recognisable affordance across sessions.
class ProfileActionButton extends ConsumerWidget {
  const ProfileActionButton({super.key});

  static const double _size = 36;
  static const double _borderWidth = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final String email = SupabaseService.session?.user.email ?? '';
    final String letter = email.isEmpty
        ? '?'
        : email.substring(0, 1).toUpperCase();
    final Color borderColor = letterPaletteColor(letter);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: InkWell(
        onTap: () => context.pushNamed(ProfileScreen.routeName),
        customBorder: const CircleBorder(),
        child: Container(
          width: _size,
          height: _size,
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
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: borderColor,
            ),
          ),
        ),
      ),
    );
  }
}
