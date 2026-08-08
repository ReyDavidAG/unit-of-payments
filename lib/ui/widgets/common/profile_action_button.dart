import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../screens/profile/profile_screen.dart';

/// The profile IconButton that sits in the AppBar of every authenticated
/// tab screen. Same icon, same handler, same tooltip — repeated literally
/// in each tab so the AppBar action stays consistent across the app.
class ProfileActionButton extends StatelessWidget {
  const ProfileActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => context.pushNamed(ProfileScreen.routeName),
      // account_circle_outlined reads as a profile slot / avatar
      // rather than a generic head silhouette, so it doesn't compete
      // with the user's actual subscription cards.
      icon: const Icon(Icons.account_circle_outlined),
      tooltip: 'Perfil',
    );
  }
}
