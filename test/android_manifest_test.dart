import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The Android side of notifications lives in a file Dart never imports, so
/// nothing else in this suite can notice when it regresses.
///
/// flutter_local_notifications ships **no receivers of its own** — its plugin
/// manifest declares two permissions and nothing else. Every receiver has to be
/// declared here, and a missing one fails silently: scheduling succeeds, the
/// alarm fires, and no notification is ever drawn.
void main() {
  final String manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();

  const String pkg = 'com.dexterous.flutterlocalnotifications';

  test('the receiver that draws a scheduled notification is declared', () {
    expect(
      manifest,
      contains('$pkg.ScheduledNotificationReceiver'),
      reason:
          'Without it a reminder is scheduled, the alarm goes off, and '
          'nothing appears. This is exactly how it broke once.',
    );
  });

  test('reminders survive a reboot', () {
    expect(manifest, contains('$pkg.ScheduledNotificationBootReceiver'));
    expect(manifest, contains('android.intent.action.BOOT_COMPLETED'));
    expect(
      manifest,
      contains('android.permission.RECEIVE_BOOT_COMPLETED'),
      reason: 'The boot receiver never runs without the permission.',
    );
  });

  test('Android 13 can be asked for the runtime permission', () {
    expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
  });
}
