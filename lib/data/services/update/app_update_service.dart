import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/environment.dart';
import '../../services/supabase/supabase_service.dart';

/// Wraps every external surface the in-app update flow talks to: the
/// Supabase Edge Function for release notes and force flag, and the
/// `in_app_update` plugin for the Play Store handshake and the actual
/// download. Every call reports rather than throws: a missing network
/// path or a refused platform channel is not worth an error screen.
///
/// Android only. On iOS every public method is a no-op so the wrapper
/// can sit in the tree unconditionally.
class AppUpdateService {
  const AppUpdateService._();

  static const String _functionName = 'app-version-android';

  /// Returns null when the platform is not Android, the function URL is
  /// empty (feature disabled), or the network/JSON call fails. The wrapper
  /// uses null to mean "no update to surface", which is the right outcome
  /// for a cold start on a fresh install or a flaky network.
  static Future<RemoteUpdateConfig?> fetchRemoteConfig() async {
    if (!Platform.isAndroid) return null;
    if (Environment.appVersionFunctionUrl.isEmpty) return null;
    try {
      final FunctionResponse response = await SupabaseService.client.functions
          .invoke(_functionName, method: HttpMethod.get);
      final dynamic data = response.data;
      if (data is! Map) return null;
      return RemoteUpdateConfig(
        releaseNotes: data['releaseNotes'] as String?,
        forceUpdate: data['forceUpdate'] as bool? ?? false,
      );
    } on Object catch (error) {
      developer.log(
        'fetchRemoteConfig failed: $error',
        name: 'AppUpdateService',
      );
      return null;
    }
  }

  /// Hands back Play Store's view of availability. Null means "we could not
  /// tell" — the wrapper treats that as "no update", same as `updateNotAvailable`.
  static Future<AppUpdateInfo?> checkPlayStoreUpdate() async {
    if (!Platform.isAndroid) return null;
    try {
      return await InAppUpdate.checkForUpdate();
    } on Object catch (error) {
      developer.log('checkForUpdate failed: $error', name: 'AppUpdateService');
      return null;
    }
  }

  /// Reads `pubspec.yaml` so the wrapper can show the installed version in
  /// debug logs. Null on platforms or builds where the plugin is not wired.
  static Future<String?> installedVersion() async {
    if (!Platform.isAndroid) return null;
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      return info.version;
    } on Object catch (error) {
      developer.log(
        'installedVersion failed: $error',
        name: 'AppUpdateService',
      );
      return null;
    }
  }

  /// Kicks off a background download. The wrapper does not await a result;
  /// progress and completion come through [installStatusStream].
  static Future<void> startFlexibleUpdate() async {
    if (!Platform.isAndroid) return;
    try {
      await InAppUpdate.startFlexibleUpdate();
    } on PlatformException catch (error) {
      developer.log(
        'startFlexibleUpdate refused: ${error.message}',
        name: 'AppUpdateService',
      );
    } on MissingPluginException catch (error) {
      developer.log(
        'startFlexibleUpdate unavailable: $error',
        name: 'AppUpdateService',
      );
    }
  }

  /// Triggers the OS-level install dialog once the APK is on disk. The
  /// process restarts after this resolves, so the wrapper does not try to
  /// update UI state after calling it.
  static Future<void> completeFlexibleUpdate() async {
    if (!Platform.isAndroid) return;
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } on PlatformException catch (error) {
      developer.log(
        'completeFlexibleUpdate refused: ${error.message}',
        name: 'AppUpdateService',
      );
    } on MissingPluginException catch (error) {
      developer.log(
        'completeFlexibleUpdate unavailable: $error',
        name: 'AppUpdateService',
      );
    }
  }

  /// The only signal that tells us "downloaded and ready". The wrapper
  /// subscribes here and removes its progress panel on the first download
  /// event.
  static Stream<InstallStatus> installStatusStream() {
    if (!Platform.isAndroid) return const Stream<InstallStatus>.empty();
    return InAppUpdate.installUpdateListener;
  }
}

/// Holds the Edge Function payload. The wrapper reads [releaseNotes] and
/// [forceUpdate]; the rest of the response (versionCode, versionName) is
/// not surfaced in the UI yet.
class RemoteUpdateConfig {
  const RemoteUpdateConfig({this.releaseNotes, this.forceUpdate = false});

  final String? releaseNotes;
  final bool forceUpdate;
}
