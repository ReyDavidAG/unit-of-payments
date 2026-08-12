import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/constants/app_version.dart';

/// Reads the running build's version once and exposes it. The plugin caches
/// the result internally, so multiple watchers do not cause multiple
/// platform-channel calls.
final FutureProvider<AppVersion> appVersionProvider =
    FutureProvider<AppVersion>((ref) async {
      final PackageInfo info = await PackageInfo.fromPlatform();
      return AppVersion(
        name: info.version,
        build: int.tryParse(info.buildNumber) ?? 0,
      );
    });
