import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Device-side scheduling. No push service, no server: renewal dates are
/// deterministic and known the moment a subscription is created.
class LocalNotificationService {
  const LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'upcoming_payments';

  /// iOS refuses to keep more than 64 pending local notifications. The
  /// scheduler works a 30-day window and reschedules on every launch, so this
  /// is the ceiling it trims to.
  static const int maxPending = 60;

  /// Reminders fire mid-morning: a payment notice at 3am is a notification
  /// people turn off.
  static const int hourOfDay = 9;

  static bool _ready = false;

  /// Returns false when the platform side is unavailable — most often a hot
  /// restart after the plugin was added, where the native registrant has not
  /// run. Reminders are optional, so this reports rather than throws.
  static Future<bool> initialize() async {
    if (_ready) {
      return true;
    }
    tz_data.initializeTimeZones();
    // ponytail: fixed zone, swap for profiles.timezone when settings exist.
    tz.setLocalLocation(tz.getLocation('America/Mexico_City'));

    _ready = await _guard('initialize', () async {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            // Asked for explicitly below, so the first launch is not a
            // permission prompt before the user has seen anything.
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      return true;
    });
    return _ready;
  }

  /// Returns false when the user declined, or when the platform side is
  /// missing. Callers keep working: the app is still useful without reminders.
  static Future<bool> requestPermission() async {
    if (!await initialize()) {
      return false;
    }
    return _guard('requestPermission', _requestPermission);
  }

  static Future<bool> _requestPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final IOSFlutterLocalNotificationsPlugin? ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;
  }

  static Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) => _guard('schedule', () async {
    await _scheduleOne(id: id, title: title, body: body, when: when);
    return true;
  });

  static Future<void> _scheduleOne({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) => _plugin.zonedSchedule(
    id: id,
    title: title,
    body: body,
    scheduledDate: tz.TZDateTime.from(when, tz.local),
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Cobros próximos',
        channelDescription: 'Aviso antes de cada cobro de suscripción',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    ),
    // Inexact on purpose: an exact alarm needs a separate permission on
    // Android 14+, and a payment reminder does not need to the second.
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
  );

  static Future<void> cancelAll() =>
      _guard('cancelAll', () async => _plugin.cancelAll().then((_) => true));

  /// One place where an unavailable platform channel stops being an exception
  /// and becomes a logged false. Without it a missing plugin takes down the
  /// whole app over a feature the user can live without.
  static Future<bool> _guard(
    String action,
    Future<bool> Function() body,
  ) async {
    try {
      return await body();
    } on MissingPluginException {
      developer.log(
        'notifications unavailable ($action) — full restart needed after '
        'adding the plugin',
        name: 'LocalNotificationService',
      );
      return false;
    } on PlatformException catch (error) {
      developer.log(
        'notifications refused ($action): ${error.message}',
        name: 'LocalNotificationService',
      );
      return false;
    }
  }
}
