import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/helpers/money_helper.dart';
import '../../models/profile/profile_model.dart';
import '../../services/notifications/local_notification_service.dart';
import '../../services/profile/profile_service.dart';
import '../auth/auth_provider.dart';

final AsyncNotifierProvider<ProfileNotifier, ProfileModel?> profileProvider =
    AsyncNotifierProvider<ProfileNotifier, ProfileModel?>(ProfileNotifier.new);

class ProfileNotifier extends AsyncNotifier<ProfileModel?> {
  @override
  Future<ProfileModel?> build() async {
    if (ref.watch(currentUserIdProvider) == null) {
      return null;
    }
    final ProfileModel? profile = await ProfileService.fetch();
    _apply(profile);
    return profile;
  }

  Future<void> save(ProfileModel profile) async {
    final ProfileModel saved = await ProfileService.save(profile);
    _apply(saved);
    state = AsyncData(saved);
  }

  /// Formatting and scheduling read their settings from here, so a change
  /// lands everywhere without each screen knowing about the profile.
  void _apply(ProfileModel? profile) {
    if (profile == null) {
      return;
    }
    MoneyHelper.configure(SupportedCurrency.fromCode(profile.currency));
    LocalNotificationService.configureTimezone(profile.timezone);
  }
}
